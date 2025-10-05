module Api
  class SubcategoriesController < ApplicationController
    skip_before_action :authenticate_request
    before_action :set_category, except: [:all_subcategory]

    def index
      subcategories = @category.subcategories
      if subcategories.exists?
        render json: { data: ActiveModelSerializers::SerializableResource.new(subcategories, each_serializer: SubcategorySerializer), message: "Subcategories fetched successfully" }, status: :ok
      else
        render json: { errors: "No subcategories found" }, status: :not_found
      end
    end
    
    def all_subcategory
      subcategories = Subcategory.all
      if subcategories.exists?
        render json: { data: ActiveModelSerializers::SerializableResource.new(subcategories, each_serializer: SubcategorySerializer), message: "Subcategories fetched successfully" }, status: :ok
      else
        render json: { errors: "No subcategories found" }, status: :not_found
      end
    end

    def show
      subcategory = @category.subcategories.find_by(id: params[:id])
      if subcategory.exists?
        render json: { data: SubcategorySerializer.new(subcategory), message: "Subcategory details fetched successfully" }, status: :ok
      else
        render json: { errors: "Subcategory not found" }, status: :not_found
      end
    end

    private

    def set_category
      @category = Category.find_by!(slug: params[:category_slug])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Category not found' }, status: :not_found 
    end
  end
end
