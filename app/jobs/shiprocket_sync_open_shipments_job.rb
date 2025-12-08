class ShiprocketSyncOpenShipmentsJob < ApplicationJob
  queue_as :default

  def perform
    ShiprocketShipment.where(status: ['created', 'shipped', 'out_for_delivery', 'in_transit', nil]).find_each do |shipment|
      ShiprocketSyncShipmentStatusJob.perform_later(shipment.id)
    end
  end
end
