ActiveAdmin.register Account do

  actions :index, :show
  
  index do
    selectable_column
    id_column
    column :full_name
    column :email
    column :mobile
    column :status
    column :account_type
    actions
  end
  
  filter :full_name
  filter :email
  filter :mobile
  filter :status
  filter :account_type

  show do
    attributes_table do
      row :full_name
      row :email
      row :mobile
      row :status
      row :account_type
    end
  end
end