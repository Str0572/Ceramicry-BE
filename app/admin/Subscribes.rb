ActiveAdmin.register Subscribe do

  actions :show, :index, :destroy
  
  index do
    selectable_column
    id_column
    column :email
    actions
  end

  show do
    attributes_table do
      row :email
    end
  end

  filter :email
  filter :created_at
end