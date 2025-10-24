class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :slug, :sku, :description, :tax_rate, :average_rating, :review_count, :material, :pieces_count, :brand, :is_featured, :is_new, :views_count, :features, :specifications, :whats_included

  has_many :variants, serializer: VariantSerializer
  belongs_to :subcategory

  def features
    object.product_features.pluck(:name)
  end

  def specifications
    object.product_specifications.each_with_object({}) do |spec, hash|
      hash[spec.key] = spec.value
    end
  end

  def whats_included
    object.product_includes.pluck(:item)
  end
end
