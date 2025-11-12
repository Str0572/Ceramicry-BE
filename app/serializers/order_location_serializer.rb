class OrderLocationSerializer < ActiveModel::Serializer
  attributes :id, :order_id, :delivery_agent_id, :latitude, :longitude, :recorded_at
end
