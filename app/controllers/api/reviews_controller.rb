module Api
  class ReviewsController < ApplicationController
    before_action :set_product
    before_action :authenticate_request

    def index
      reviews = @product.reviews.order(created_at: :desc)
      if reviews.exists?
        render json: { data: ActiveModelSerializers::SerializableResource.new(reviews, each_serializer: ReviewSerializer)  }, status: :ok
      else
        render json: { errors: "No reviews found"}, status: :not_found
      end
    end

    def create
      review = @product.reviews.new(review_params)
      review.account = current_user
      review.verified = user_verified?

      if review.save
        render json: { data: ReviewSerializer.new(review), message: "Review created successfully" }, status: :created
      else
        render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def review_params
      params.require(:review).permit(:title, :comment, :rating)
    end

    def user_verified?
      current_user.status?
    end
  end
end
