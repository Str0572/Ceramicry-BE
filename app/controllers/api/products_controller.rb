module Api
  class ProductsController < ApplicationController
    skip_before_action :authenticate_request

    def index
      products = Product.includes(:variants, subcategory: :category).all

      if params[:subcategory].present?
        subcategory = Subcategory.find_by(slug: params[:subcategory])
        return render json: { data: [], message: "No products found" }, status: :not_found unless subcategory
        products = subcategory ? subcategory.products : Product.none
      end

      if params[:category].present?
        category = Category.find_by(slug: params[:category])
        return render json: { data: [], message: "No products found" }, status: :not_found unless category
        products = category ? products.joins(:subcategory).where(subcategories: { category_id: category.id }) : Product.none
      end

      products = products.joins(:variants).distinct
      products = products.where("variants.price >= ?", params[:min_price]) if params[:min_price].present?
      products = products.where("variants.price <= ?", params[:max_price]) if params[:max_price].present?
      products = products.where(material: params[:material]) if params[:material].present?

      products = case params[:sort_by]
            when "low_to_high" then products.order("variants.price ASC")
            when "high_to_low" then products.order("variants.price DESC")
            when "newest" then products.order(created_at: :desc)
            else products.order(created_at: :asc)
            end

      if products.exists?
        render json: {
          data: ActiveModelSerializers::SerializableResource.new(products, each_serializer: ProductSerializer),
          products_count: products.size,
          message: "Product list fetched successfully"
        }, status: :ok
      else
        render json: { data: [], message: "No products found" }, status: :ok
      end
    end

    def show
      product = Product.find_by(slug: params[:id])

      if product
        render json: { data: ProductSerializer.new(product), message: "Product details fetched successfully" }, status: :ok
      else
        render json: { errors: "Product not found" }, status: :not_found
      end
    end

    def search
      query = params[:q]&.strip

      products = Product.where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%").includes(:variants)

      if products.exists?
        render json: {
          data: ActiveModelSerializers::SerializableResource.new(products, each_serializer: ProductSerializer),
          products_count: products.size, message: "Products matching '#{query}' fetched successfully"
        }, status: :ok
      else
        render json: { errors: "No products found for '#{query}'" }, status: :not_found
      end
    end
  end
end
