ActiveAdmin.register Category do
  permit_params :name, :description, :slug

  config.batch_actions = true

  index do
    selectable_column
    column :name
    column :slug
    column :description
    actions
  end

  filter :name

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
    end
    f.actions
  end

  show do
		attributes_table do
	    row :name
	    row :slug
	    row :description
		end  
  end

  controller do
    def find_resource
      Category.find_by!(slug: params[:id])
    end
  end
  action_item :import, only: :index do
    link_to 'Import CSV/XLSX', import_admin_categories_path
  end

  collection_action :import, method: :get do
    render inline: <<-ERB
      <h3>Import Categories</h3>
      <p>Columns: name, slug, description</p>
      <%= form_with url: do_import_admin_categories_path, multipart: true, method: :post do |f| %>
        <%= f.file_field :file, required: true %>
        <%= f.submit 'Upload' %>
      <% end %>
    ERB
  end

  collection_action :do_import, method: :post do
    if params[:file].blank?
      redirect_to admin_categories_path, alert: 'Please attach a file.' and return
    end
    result = Importers::CategoryImporter.new(params[:file]).call
    notice = "Imported: #{result.results[:created]} created, #{result.results[:updated]} updated"
    if result.errors.any?
      redirect_to admin_categories_path, alert: (notice + ". Errors: #{result.errors.first(5).join('; ')}")
    else
      redirect_to admin_categories_path, notice: notice
    end
  end
end
