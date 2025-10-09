module Api
  class OffersController < ApplicationController
    before_action :set_offer, only: [:apply]
    before_action :authenticate_request, except: [:index]

    def index
      offers = Offer.active.order(created_at: :desc)
      render json:  { data: ActiveModelSerializers::SerializableResource.new(offers, each_serializer: OfferSerializer) }, status: :ok
    end

    def apply
      total_amount = params[:total_amount].to_f
      account = current_user

      return render json: { errors: "Invalid Coupon" }, status: :not_found unless @offer

      if @offer.expired?
        return render json: { errors: "Coupon has expired" }, status: :unprocessable_entity
      end

      if total_amount < @offer.min_order
        return render json: { errors: "Minimum order value not met (₹#{@offer.min_order})" }, status: :unprocessable_entity
      end

      if @offer.usage_exceeded?
        return render json: { errors: "Offer usage limit reached" }, status: :unprocessable_entity
      end

      if OfferUsage.exists?(offer: @offer, account: account)
        return render json: { errors: "You’ve already used this offer" }, status: :unprocessable_entity
      end

      discount = @offer.apply_discount(total_amount)

      OfferUsage.create!(offer: @offer, account: account, used_at: Time.current)

      render json: {
        message: "Offer applied successfully",
        discount: discount,
        final_amount: total_amount - discount
      }, status: :ok
    end

    private

    def set_offer
      @offer = Offer.find_by(code: params[:code].to_s)
    end
  end
end
