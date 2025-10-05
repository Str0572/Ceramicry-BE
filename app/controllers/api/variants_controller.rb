module Api
  class VariantsController < ApplicationController
    skip_before_action :authenticate_request
    before_action :set_product

    def index
      variants = @product.variants
      if variants.exists?
        render json: {data: ActiveModelSerializers::SerializableResource.new(variants, each_serializer: VariantSerializer), message: "Variant list fetched successfully"} , status: :ok
      else
        render json: { errors: "No variants available"}, status: :not_found
      end
    end

    def show
      variant = @product.variants.find_by(id: params[:id])
      if variant.exists?
        render json: { data: VariantSerializer.new(variant), message: "Variant details fetched successfully" }, status: :ok
      else
        render json: { errors: "Variant not found" }, status: :not_found
      end
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    end
  end
end
