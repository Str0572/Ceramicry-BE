ActiveAdmin.register DeliveryAgent do
  permit_params :full_name, :phone, :email, :password, :password_confirmation, :latitude, :longitude, :active

  index do
    selectable_column
    id_column
    column :full_name
    column :phone
    column :email
    column :active
    column :last_seen_at
    actions
  end

  filter :full_name
  filter :email
  filter :phone
  filter :active

  form do |f|
    f.inputs "Delivery Agent Details" do
      f.input :full_name
      f.input :phone
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :active
    end
    f.actions
  end
end


