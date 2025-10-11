class SubcategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :slug, :description, :product_count

  def product_count
    object.products.count
  end

  belongs_to :category
end
