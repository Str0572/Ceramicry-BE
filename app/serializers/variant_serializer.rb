class VariantSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :sku, :size, :color, :price, :original_price, :discount_percentage, :stock_quantity, :product_id, :product_images

  def product_images
    return [] unless object.product_images.attached?

    object.product_images.map do |img|
      Rails.application.routes.url_helpers.rails_blob_url(img, only_path: false)
    end
  end
end
