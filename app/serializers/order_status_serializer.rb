class OrderStatusSerializer < ActiveModel::Serializer
  attributes :id, :status, :notes, :status_display, :created_by_name, :created_at_time,
             :created_at, :updated_at

  belongs_to :created_by, serializer: AccountSerializer

  def status_display
    object.status_display
  end

  def created_by_name
    object.created_by_name
  end

  def created_at_time
    object.created_at_time
  end
end

