ActiveAdmin.register Subcategory do
  permit_params :name, :slug, :description, :category_id, :img_icon

  config.batch_actions = true

  index do
    selectable_column
    column :name
    column :slug
    column :description
    column "Category" do |subcategory|
      subcategory&.category&.name if subcategory.category
    end
    actions
  end

  filter :name
  filter :category_id

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :img_icon, as: :file, hint: (
        f.object.img_icon.attached? ?
          image_tag(url_for(f.object.img_icon), size: "100x100") :
          content_tag(:span, "No icon uploaded yet")
      )
      f.input :category_id, as: :select, collection: Category.all.pluck(:name, :id)
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :slug
      row :description
      row "Category" do |subcategory|
        subcategory&.category&.name if subcategory.category
      end
      row :img_icon do |subcategory|
        if subcategory.img_icon.attached?
          image_tag url_for(subcategory.img_icon), size: "120x120"
        else
          status_tag "No Image"
        end
      end
    end
  end

  controller do
    def find_resource
      Subcategory.find_by!(slug: params[:id])
    end
  end
  action_item :import, only: :index do
    link_to 'Import CSV/XLSX', import_admin_subcategories_path
  end

  collection_action :import, method: :get do
    render inline: <<-ERB
      <h3>Import Subcategories</h3>
      <p>Columns: name, slug, category_slug, description</p>
      <%= form_with url: do_import_admin_subcategories_path, multipart: true, method: :post do |f| %>
        <%= f.file_field :file, required: true %>
        <%= f.submit 'Upload' %>
      <% end %>
    ERB
  end

  collection_action :do_import, method: :post do
    if params[:file].blank?
      redirect_to admin_subcategories_path, alert: 'Please attach a file.' and return
    end
    result = Importers::SubcategoryImporter.new(params[:file]).call
    notice = "Imported: #{result.results[:created]} created, #{result.results[:updated]} updated"
    if result.errors.any?
      redirect_to admin_subcategories_path, alert: (notice + ". Errors: #{result.errors.first(5).join('; ')}")
    else
      redirect_to admin_subcategories_path, notice: notice
    end
  end
end
