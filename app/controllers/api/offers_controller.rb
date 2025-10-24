module Api
  class OffersController < ApplicationController
    before_action :authenticate_request
    before_action :set_offer, only: [:apply]

    def index
      offers = Offer.active.order(created_at: :desc)
      render json:  { data: ActiveModelSerializers::SerializableResource.new(offers, each_serializer: OfferSerializer) }, status: :ok
    end

    def apply
      total_amount = params[:total_amount].to_f
      account = current_user

      return render json: { errors: "Invalid Coupon" }, status: :not_found unless @offer
      return render json: { errors: "Coupon expired" }, status: :unprocessable_entity if @offer.expired?
      return render json: { errors: "Minimum order ₹#{@offer.min_order} required" }, status: :unprocessable_entity if total_amount < @offer.min_order
      return render json: { errors: "Offer usage limit reached" }, status: :unprocessable_entity if @offer.usage_exceeded?
      return render json: { errors: "You’ve already used this offer" }, status: :unprocessable_entity if OfferUsage.exists?(offer: @offer, account: account)

      discount = @offer.apply_discount(total_amount)

      OfferUsage.create!(offer: @offer, account: account, used_at: Time.current)

      render json: {
        message: "Offer applied successfully",
        discount: discount.round(2),
        final_amount: (total_amount - discount).round(2)
      }, status: :ok
    end

    def available
      subtotal = current_user.cart&.cart_items&.sum(:total_price) || 0
      offers = Offer.available_for_account(current_user, subtotal)
      render json: { data: ActiveModelSerializers::SerializableResource.new(offers, each_serializer: OfferSerializer) }
    end

    private

    def set_offer
      @offer = Offer.find_by(code: params[:code].to_s.strip.upcase)
    end
  end
end
