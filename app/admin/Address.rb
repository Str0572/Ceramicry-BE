ActiveAdmin.register Address do

  actions :index, :show
  
  index do
    selectable_column
    id_column
    column :name
    column :phone
    column :address_line1
    column :address_line2
    column :city
    column :state
    column :pincode
    column :country
    column :address_type
    column :is_default
    column "Account" do |a|
      a.account&.full_name if a.account
    end
    actions
  end
  
  filter :country
  filter :state
  filter :city
  filter :pincode

  show do
    attributes_table do
      row :name
      row :phone
      row :address_line1
      row :address_line2
      row :city
      row :state
      row :pincode
      row :country
      row :address_type
      row :is_default
      row "Account" do |a|
        a.account&.full_name if a.account
      end 
    end
  end
end