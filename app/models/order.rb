class Order < ApplicationRecord
  belongs_to :account
  belongs_to :shipping_address, class_name: 'Address'
  belongs_to :billing_address, class_name: 'Address'
  has_many :order_items, dependent: :destroy
  has_many :order_statuses, dependent: :destroy
  has_many :products, through: :order_items

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

  before_validation :generate_order_number, on: :create
  before_validation :calculate_totals
  after_create :create_initial_status

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_payment_status, ->(payment_status) { where(payment_status: payment_status) }
  after_update :track_status_change, if: :saved_change_to_status?

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

  before_save :set_default_estimated_delivery

  def set_default_estimated_delivery
    self.estimated_delivery ||= 5.days.from_now.in_time_zone('Asia/Kolkata')
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
      
      # Update timestamps for specific statuses
      case new_status
      when 'shipped'
        update!(shipped_at: Time.current)
      when 'delivered'
        update!(delivered_at: Time.current)
      when 'cancelled'
        update!(cancelled_at: Time.current)
      end
    end
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

  private

  def generate_order_number
    self.order_number ||= self.class.generate_order_number
  end

  def calculate_totals
    self.subtotal = order_items.sum(:total_price)
    self.total_amount = subtotal + tax_amount + shipping_amount - discount_amount
  end

  def create_initial_status
    order_statuses.create!(
      status: 'pending',
      notes: 'Order Placed Successfully.',
      created_by: account
    )
  end

  def valid_status_transition?(new_status)
    valid_transitions = {
      'pending' => %w[confirmed cancelled],
      'confirmed' => %w[processing cancelled],
      'processing' => %w[shipped cancelled],
      'shipped' => %w[delivered out_for_delivery],
      'delivered' => %w[returned refunded],
      'cancelled' => [],
      'refunded' => []
    }
    
    valid_transitions[status]&.include?(new_status) || false
  end

  def track_status_change
    order_statuses.create!(
      status: status,
      notes: "Status changed to #{status.humanize} via admin.",
      created_by: account
    )
  end
end
