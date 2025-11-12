class DeliveryAgentSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :phone, :email, :latitude, :longitude, :last_seen_at
end
