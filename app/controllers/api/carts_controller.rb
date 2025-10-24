module Api
  class CartsController < ApplicationController
    before_action :authenticate_request
    before_action :set_cart
    before_action :set_cart_item, only: [:update_item, :remove_item]

    def current_cart
      if @cart&.cart_items.exists?
        total_qty = @cart.cart_items.sum(:qty)
        total_price = @cart.cart_items.sum(:total_price)

        render json: { data: CartSerializer.new(@cart) }, status: :ok
      else
        render json: { message: "Cart is empty" }, status: :ok
      end
    end

    def add_item
      product = Product.find_by(id: params[:product_id])
      variant = product&.variants&.find_by(id: params[:variant_id])

      return render json: { errors: "Product or variant not found" }, status: :not_found unless product && variant
      return render json: { errors: "Product not available for sale" }, status: :unprocessable_entity unless product.sellable? && variant.sellable?

      quantity_to_add = params[:qty].to_i.positive? ? params[:qty].to_i : 1
      price = variant&.price
      item = @cart.cart_items.find_by(product: product, variant: variant)

      if item
        item.qty += quantity_to_add
        item.total_price = item.qty * price
        item.save!
      else
        @cart.cart_items.create!(
          product: product,
          variant: variant,
          qty: quantity_to_add,
          total_price: price * quantity_to_add
        )
      end

      render json: { data: CartSerializer.new(@cart) }, status: :created
    end

    def update_item
      qty = params[:qty].to_i
      return render json: { errors: "Quantity must be greater than 0" }, status: :unprocessable_entity if qty <= 0

      price = @item.variant&.price
      @item.update!(qty: qty, total_price: qty * price)

      if @item.save
        render json: { data: CartSerializer.new(@cart) }, status: :ok
      else
        render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def remove_item
      @item.destroy

      if @cart.cart_items.count.zero?
        return render json: { message: "Cart is empty" }, status: :ok
      end

      render json: { data: CartSerializer.new(@cart) }, status: :ok
    end

    private

    def set_cart
      @cart = current_user.cart || current_user.create_cart
      return render json: { errors: "Cart not found" }, status: :not_found unless @cart
    end

    def set_cart_item
      @item = @cart.cart_items.find_by(id: params[:cart_item_id])
      return render json: { errors: "Cart item not found" }, status: :not_found unless @item
    end
  end
end
