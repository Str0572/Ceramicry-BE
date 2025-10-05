module Api
  class CategoriesController < ApplicationController
    skip_before_action :authenticate_request

    def index
      categories = Category.all
      if categories.exists?
        render json: { data: ActiveModelSerializers::SerializableResource.new(categories, each_serializer: CategorySerializer), message: "Categories fetched successfully" }, status: :ok
      else
        render json: { errors: "No categories found" }, status: :not_found
      end
    end

    def show
      category = Category.find_by(id: params[:id])
      if category.exists?
        render json: { data: CategorySerializer.new(category), message: "Category details fetched successfully" }, status: :ok
      else
        render json: { errors: "Category not found" }, status: :not_found
      end
    end

  end
end
