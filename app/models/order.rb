class Order < ApplicationRecord
  belongs_to :account
  belongs_to :shipping_address, class_name: 'Address'
  belongs_to :billing_address, class_name: 'Address'
  has_many :order_items, dependent: :destroy
  has_many :order_statuses, dependent: :destroy
  has_many :products, through: :order_items
  belongs_to :delivery_agent, optional: true
  has_many :order_locations, dependent: :destroy
  has_one :shiprocket_shipment, dependent: :destroy
  has_one :delhivery_shipment, dependent: :destroy
  has_one_attached :proof_of_delivery

  # Order statuses
  enum :status, {
    pending: 'pending',
    confirmed: 'confirmed',
    processing: 'processing',
    shipped: 'shipped',
    out_for_delivery: 'out_for_delivery',
    delivered: 'delivered',
    cancelled: 'cancelled',
    returned: 'returned',
    refunded: 'refunded'
  }

  # Payment statuses
  enum :payment_status, {
    payment_pending: 'pending',
    paid: 'paid',
    failed: 'failed',
    payment_refunded: 'refunded',
    partially_refunded: 'partially_refunded'
  }

  # Payment methods
  enum :payment_method, {
    cash_on_delivery: 'cash_on_delivery',
    online_payment: 'online_payment',
    wallet: 'wallet'
  }

  validates :order_number, presence: true, uniqueness: true
  validates :subtotal, :tax_amount, :shipping_amount, :discount_amount, :total_amount,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: statuses.keys }
  validates :payment_status, inclusion: { in: payment_statuses.keys }
  validates :payment_method, inclusion: { in: payment_methods.keys }, allow_nil: true

  before_validation :assign_order_number, on: :create, unless: -> { order_number.present? }
  before_validation :calculate_totals
  after_create :create_initial_status
  before_save :set_default_estimated_delivery

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_payment_status, ->(payment_status) { where(payment_status: payment_status) }

  def self.generate_order_number
    "ORD#{Time.current.strftime('%Y%m%d')}#{SecureRandom.alphanumeric(4).upcase}"
  end

  def can_be_cancelled?
    %w[pending confirmed processing].include?(status)
  end

  def can_be_refunded?
    %w[delivered returned].include?(status) && payment_status == 'paid'
  end

  def can_be_shipped?
    %w[confirmed processing].include?(status)
  end

  def can_be_delivered?
    %w[shipped out_for_delivery].include?(status)
  end

  def can_be_returned?
    delivered_at.present? && delivered_at >= 7.days.ago && status == 'delivered'
  end

  def update_status!(new_status, notes: nil, created_by: nil)
    return false unless valid_status_transition?(new_status)

    transaction do
      update!(status: new_status)
      order_statuses.create!(
        status: new_status,
        notes: notes,
        created_by: created_by || account
      )
      
      case new_status
      when 'shipped'
        update!(shipped_at: Time.current)
      when 'delivered'
        update!(delivered_at: Time.current)
      when 'cancelled'
        update!(cancelled_at: Time.current)
      end
    end
    NotificationMailer.order_status_updated(account, self, new_status).deliver_now
  end

  def add_status_notes(notes, created_by: nil)
    order_statuses.create!(
      status: status,
      notes: notes,
      created_by: created_by || account
    )
  end

  def total_items
    order_items.sum(:quantity)
  end

  def formatted_order_number
    "##{order_number}"
  end

  def shipping_address_full
    shipping_address&.full_address
  end

  def billing_address_full
    billing_address&.full_address
  end

  def estimated_delivery_date
    estimated_delivery&.strftime("%d %b %Y")
  end

  def push_to_shiprocket!(created_by: nil)
    raise 'Order already has Shiprocket shipment' if shiprocket_shipment.present?

    service = ShiprocketService.new
    order_data, _raw_data = service.create_order_for(self)

    sr_order_id    = order_data['order_id'] || order_data['orderid']
    sr_shipment_id = order_data['shipment_id'] || order_data.dig('shipments', 0, 'id')

    courier_response    = service.assign_courier(sr_shipment_id)
    data = courier_response.dig('response', 'data') || {}

    awb_code           = data['awb_code']
    courier_company_id = data['courier_id']
    courier_name       = data['courier_name'] || "Mock Courier"
    last_status        = courier_response['status'].to_s.presence || "mock"

    raise "Shiprocket did not return AWB code" if awb_code.blank?

    create_shiprocket_shipment!(
      sr_order_id:          sr_order_id,
      sr_shipment_id:       sr_shipment_id,
      awb_code:             awb_code,
      courier_company_id:   courier_company_id,
      courier_name:         courier_name,
      status:               'created',
      last_shiprocket_status: last_status,
      last_synced_at:       Time.current,
      raw_order_response:   order_data,
      raw_courier_response: courier_response
    )

    update_status!('processing', notes: "Shiprocket shipment created. AWB #{awb_code}", created_by: created_by) if awb_code.present?

    self
  end

  private

  def assign_order_number
    self.order_number ||= self.class.generate_order_number
  end

  def calculate_totals
    self.subtotal ||= order_items.sum(:total_price)
    self.total_amount = subtotal.to_f + tax_amount.to_f + shipping_amount.to_f - discount_amount.to_f
  end

  def create_initial_status
    order_statuses.create!(
      status: 'pending',
      notes: 'Order Placed Successfully.',
      created_by: account
    )
  end

  def set_default_estimated_delivery
    self.estimated_delivery ||= 5.days.from_now.in_time_zone('Asia/Kolkata')
  end

  def valid_status_transition?(new_status)
    valid_transitions = {
      'pending' => %w[confirmed cancelled],
      'confirmed' => %w[processing cancelled],
      'processing' => %w[shipped cancelled],
      'shipped' => %w[out_for_delivery delivered],
      'out_for_delivery' => %w[delivered],
      'delivered' => %w[returned refunded],
      'returned' => %w[refunded],
      'cancelled' => [],
      'refunded' => []
    }
    
    valid_transitions[status]&.include?(new_status)
  end
end
