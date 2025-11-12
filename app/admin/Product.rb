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
  action_item :import, only: :index do
    link_to 'Import CSV/XLSX', import_admin_products_path
  end

  collection_action :import, method: :get do
    render inline: <<-ERB
      <h3>Import Products</h3>
      <p>Columns: name, slug, sku, subcategory_slug, material, pieces_count, brand, is_featured, is_new, tax_rate</p>
      <%= form_with url: do_import_admin_products_path, multipart: true, method: :post do |f| %>
        <%= f.file_field :file, required: true %>
        <%= f.submit 'Upload' %>
      <% end %>
    ERB
  end

  collection_action :do_import, method: :post do
    if params[:file].blank?
      redirect_to admin_products_path, alert: 'Please attach a file.' and return
    end
    result = Importers::ProductImporter.new(params[:file]).call
    notice = "Imported: #{result.results[:created]} created, #{result.results[:updated]} updated"
    if result.errors.any?
      redirect_to admin_products_path, alert: (notice + ". Errors: #{result.errors.first(5).join('; ')}")
    else
      redirect_to admin_products_path, notice: notice
    end
  end
end
