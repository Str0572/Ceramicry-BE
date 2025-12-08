class CheckoutService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account_id, :integer
  attribute :shipping_address_id, :integer
  attribute :billing_address_id, :integer
  attribute :payment_method, :string
  attribute :notes, :string
  attribute :offer_code, :string
  attribute :order_number, :string

  validates :account_id, :shipping_address_id, :billing_address_id, presence: true
  validates :payment_method, inclusion: { in: Order.payment_methods.keys }, allow_blank: true

  def initialize(attributes = {})
    super
    @account = Account.find(account_id) if account_id.present?
    @shipping_address = Address.find(shipping_address_id) if shipping_address_id.present?
    @billing_address = Address.find(billing_address_id) if billing_address_id.present?
    @offer = Offer.find_by(code: offer_code.to_s.upcase) if offer_code.present?
    @order_number = attributes[:order_number]
  end

  def call
    return false unless valid?

    ActiveRecord::Base.transaction do
      create_order
      create_order_items
      update_inventory_quantities
      apply_discounts
      recalculate_totals
      clear_cart
    end
    NotificationMailer.order_created(@account, @order).deliver_now if @order
    @order
  rescue => e
    errors.add(:base, "Checkout failed: #{e.message}")
    false
  end

  def order
    @order
  end

  private

  def create_order
    @order = Order.create!(
      account: @account,
      shipping_address: @shipping_address,
      billing_address: @billing_address,
      payment_method: payment_method || 'cash_on_delivery',
      notes: notes,
      subtotal: cart_subtotal,
      tax_amount: calculate_tax,
      shipping_amount: calculate_shipping,
      discount_amount: 0,
      total_amount: cart_subtotal + calculate_tax + calculate_shipping,
      order_number: @order_number
    )
  end

  def create_order_items
    cart_items.each do |cart_item|
      unit_price = cart_item.variant&.price
      tax_rate = cart_item.product.tax_rate || 0

      OrderItem.create!(
        order: @order,
        product: cart_item.product,
        variant: cart_item.variant,
        quantity: cart_item.qty,
        unit_price: unit_price,
        total_price: cart_item.total_price,
        tax_rate: tax_rate,
        tax_amount: (unit_price * tax_rate / 100.0 * cart_item.qty).round(2)
      )
    end
  end

  def update_inventory_quantities
    @order.order_items.each do |order_item|
      if order_item&.variant
        new_quantity = [order_item.variant&.stock_quantity - order_item.quantity, 0].max
        order_item.variant.update!(stock_quantity: new_quantity)
      end

      new_pieces_count = [order_item.product&.pieces_count - order_item.quantity, 0].max
      order_item.product.update!(pieces_count: new_pieces_count)
    end
  end

  def apply_discounts
    return unless @offer
    return unless @offer.valid_for?(@account, cart_subtotal)

    discount_amount = @offer.apply_discount(cart_subtotal)
    @order.update!(discount_amount: discount_amount)

    OfferUsage.create!(offer: @offer, account: @account)
  end

  def recalculate_totals
    @order.reload
    subtotal = @order.order_items.sum(:total_price)
    tax_amount = @order.order_items.sum(:tax_amount)
    shipping_amount = calculate_shipping
    discount_amount = @order.discount_amount

    @order.update!(
      subtotal: subtotal,
      tax_amount: tax_amount,
      shipping_amount: shipping_amount,
      total_amount: subtotal + tax_amount + shipping_amount - discount_amount
    )
  end

  def clear_cart
    @account.cart.clear
  end

  def cart_items
    @account.cart ? @account.cart.cart_items.includes(:product, :variant) : []
  end

  def cart_subtotal
    return 0 unless @account&.cart
    @account.cart.cart_items.sum(:total_price) || 0
  end

  def calculate_tax
    cart_items.sum do |item|
      price = item.variant&.price
      tax_rate = item.product.tax_rate || 0
      (price * tax_rate / 100.0) * item.qty
    end.round(2)
  end

  def calculate_shipping
    cart_subtotal > 10_000 ? 0 : 199
  end
end
