class AddressSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :address_line1, :address_line2, :city, :state, :pincode, :country, :address_type, :is_default, :account_id
end