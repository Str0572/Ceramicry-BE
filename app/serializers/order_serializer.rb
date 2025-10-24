class OrderSerializer < ActiveModel::Serializer
  attributes :id, :order_number, :status, :payment_status, :payment_method, :subtotal, 
             :tax_amount, :shipping_amount, :discount_amount, :total_amount, :total_items,
             :notes, :shipped_at, :delivered_at, :cancelled_at, :created_at, :updated_at

  belongs_to :account, serializer: AccountSerializer
  belongs_to :shipping_address, serializer: AddressSerializer
  belongs_to :billing_address, serializer: AddressSerializer
  has_many :order_items, serializer: OrderItemSerializer
  has_many :order_statuses, serializer: OrderStatusSerializer

  def formatted_order_number
    "##{object.order_number}"
  end

  def status_display
    object.status.humanize
  end

  def payment_status_display
    case object.payment_status
    when 'pending'
      'Pending'
    when 'paid'
      'Paid'
    when 'failed'
      'Failed'
    when 'refunded'
      'Refunded'
    when 'partially_refunded'
      'Partially Refunded'
    else
      object.payment_status.humanize
    end
  end

  def can_be_cancelled
    object.can_be_cancelled?
  end

  def can_be_refunded
    object.can_be_refunded?
  end

  def shipping_address_full
    object.shipping_address_full
  end

  def billing_address_full
    object.billing_address_full
  end
end
