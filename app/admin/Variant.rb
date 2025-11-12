ActiveAdmin.register Variant do
  permit_params :sku, :size, :color, :price, :original_price, :discount_percentage, :stock_quantity, :product_id, product_images: []

  index do
    selectable_column
    id_column
    column :sku
    column :size
    column :color
    column :price
    column :original_price
    column :discount_percentage
    column :stock_quantity
    column "Product" do |variant|
      variant.product&.name if variant.product
    end
    column :product_images do |prod_img|
      if prod_img.product_images.attached?
        prod_img.product_images.map do |img|
          image_tag url_for(img), size: '50x50'
        end.join(' ').html_safe
      end
    end
    actions
  end

  filter :sku
  filter :size
  filter :stock_quantity
  filter :product_id, as: :select, collection: Product.all.pluck(:name, :id)

  form do |f|
    f.inputs do
      f.input :sku
      f.input :size
      f.input :color
      f.input :price
      f.input :original_price
      f.input :discount_percentage
      f.input :stock_quantity
      f.input :product_id, as: :select, collection: Product.all.pluck(:name, :id)
      if f.object.product_images.attached?
        f.object.product_images.each do |img|
          span do
            image_tag url_for(img), size: "100x100"
          end
        end
      end
      f.input :product_images, as: :file, input_html: { multiple: true }
    end
    f.actions
  end

  show do
    attributes_table do
      row :sku
      row :size
      row :color
      row :price
      row :original_price
      row :discount_percentage
      row :stock_quantity
      row "Product" do |variant|
        variant.product&.name if variant.product
      end
      row :product_images do |prod_img|
        if prod_img.product_images.attached?
          prod_img.product_images.map do |img|
            image_tag url_for(img), size: '50x50'
          end.join(' ').html_safe
        end
      end
    end
  end
  action_item :import, only: :index do
    link_to 'Import CSV/XLSX', import_admin_variants_path
  end

  collection_action :import, method: :get do
    render inline: <<-ERB
      <h3>Import Variants</h3>
      <p>Columns: product_sku, sku, size, color, price, original_price, discount_percentage, stock_quantity</p>
      <%= form_with url: do_import_admin_variants_path, multipart: true, method: :post do |f| %>
        <%= f.file_field :file, required: true %>
        <%= f.submit 'Upload' %>
      <% end %>
    ERB
  end

  collection_action :do_import, method: :post do
    if params[:file].blank?
      redirect_to admin_variants_path, alert: 'Please attach a file.' and return
    end
    result = Importers::VariantImporter.new(params[:file]).call
    notice = "Imported: #{result.results[:created]} created, #{result.results[:updated]} updated"
    if result.errors.any?
      redirect_to admin_variants_path, alert: (notice + ". Errors: #{result.errors.first(5).join('; ')}")
    else
      redirect_to admin_variants_path, notice: notice
    end
  end
end
