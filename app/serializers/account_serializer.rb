class AccountSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :mobile, :email, :status

  has_many :addresses
end