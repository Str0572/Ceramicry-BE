ActiveAdmin.register Subcategory do
  permit_params :name, :slug, :description, :category_id

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
    end
  end

  controller do
    def find_resource
      Subcategory.find_by!(slug: params[:id])
    end
  end
end
