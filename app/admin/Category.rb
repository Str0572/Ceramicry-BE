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
end
