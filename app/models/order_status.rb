class OrderStatus < ApplicationRecord
  belongs_to :order
  belongs_to :created_by, class_name: 'Account'

  # same status enum as Order
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

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  MILESTONES = [
    { key: 'pending',    name: 'Ordered',         explanation: 'We have received your order.', index: 0 },
    { key: 'confirmed',  name: 'Confirmed',       explanation: 'Your order has been confirmed.', index: 1 },
    { key: 'processing',     name: 'Packed',          explanation: 'Your items are being packed.', index: 2 },
    { key: 'shipped',    name: 'Shipped',         explanation: 'Your order has shipped!', index: 3 },
    { key: 'out_for_delivery', name: 'Out for Delivery', explanation: 'Your order is out for delivery.', index: 4 },
    { key: 'delivered',  name: 'Delivered',       explanation: 'Order delivered. We hope you enjoy!', index: 5 },
    { key: 'cancelled',  name: 'Cancelled',       explanation: 'This order was cancelled.', index: 6 },
    { key: 'returned',   name: 'Returned',        explanation: 'Order returned. Refund will be processed.', index: 7 },
    { key: 'refunded',   name: 'Refunded',        explanation: 'Order returned successfully. Refund is in processing.', index: 8 }
  ].freeze

  def self.milestone_for(status)
    MILESTONES.find { |m| m[:key] == status }
  end

  def step_index
    self.class.milestone_for(status)&.dig(:index)
  end

  def user_message
    self.class.milestone_for(status)&.dig(:explanation) || status_display
  end

  def milestone_name
    self.class.milestone_for(status)&.dig(:name) || status_display
  end

  def status_display
    status.humanize
  end

  def created_by_name
    created_by.full_name
  end

  def created_at_time
    created_at.strftime("%B %d, %Y at %I:%M %p")
  end
end
