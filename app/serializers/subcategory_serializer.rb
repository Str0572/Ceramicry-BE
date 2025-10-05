class SubcategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :slug, :description

  belongs_to :category
end
