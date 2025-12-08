class SubcategorySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :name, :slug, :description, :product_count, :img_icon

  def img_icon
    return nil unless object.img_icon.attached?

    Rails.application.routes.url_helpers.rails_blob_url(object.img_icon, only_path: false)
  end

  def product_count
    object.products.count
  end

  belongs_to :category
end
