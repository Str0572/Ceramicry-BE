ActiveAdmin.register Product do
  permit_params :name, :slug, :sku, :tax_rate, :description, :material, :pieces_count, :brand, :is_featured, :is_new, :views_count, :subcategory_id, product_features_attributes: [:id, :name, :_destroy],
  product_specifications_attributes: [:id, :key, :value, :_destroy],
  product_includes_attributes: [:id, :item, :_destroy]

  config.batch_actions = true
  
  index do
    selectable_column
    column :name
    column :slug
    column :sku
    column :tax_rate
    column :description
    column :material
    column :pieces_count
    column :brand
    column :is_featured
    column :is_new
    column :views_count
    column "Subcategory" do |product|
      product.subcategory&.name if product.subcategory
    end
    actions
  end

  filter :name
  filter :subcategory_id, as: :select, collection: Subcategory.all.pluck(:name, :id)

  form do |f|
    f.inputs do
      f.input :name
      f.input :sku
      f.input :tax_rate
      f.input :description
      f.input :material
      f.input :pieces_count
      f.input :brand
      f.input :is_featured
      f.input :is_new
      f.input :views_count
      f.input :subcategory_id, as: :select, collection: Subcategory.all.pluck(:name, :id)
    end
    f.inputs "Features" do
      f.has_many :product_features, allow_destroy: true, new_record: 'Add feature' do |ff|
        ff.input :name
      end
    end

    f.inputs "Specifications" do
      f.has_many :product_specifications, allow_destroy: true, new_record: 'Add spec' do |ff|
        ff.input :key
        ff.input :value
      end
    end

    f.inputs "What's Included" do
      f.has_many :product_includes, allow_destroy: true, new_record: 'Add included item' do |ff|
        ff.input :item
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :slug
      row :sku
      row :tax_rate
      row :description
      row :material
      row :pieces_count
      row :brand
      row :is_featured
      row :is_new
      row :views_count
      row "Subcategory" do |product|
        product.subcategory&.name if product.subcategory
      end
    end
  end

   controller do
    def find_resource
      Product.find_by!(slug: params[:id])
    end
  end
end
