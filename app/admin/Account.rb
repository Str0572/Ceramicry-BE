ActiveAdmin.register Account do

  actions :index, :show
  
  index do
    selectable_column
    id_column
    column :full_name
    column :email
    column :mobile
    column :status
    actions
  end
  
  filter :full_name
  filter :email
  filter :mobile
  filter :status

  show do
    attributes_table do
      row :full_name
      row :email
      row :mobile
      row :status
    end
  end
end