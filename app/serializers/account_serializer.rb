class AccountSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :mobile, :email, :status, :created_at, :updated_at

  has_many :addresses
end