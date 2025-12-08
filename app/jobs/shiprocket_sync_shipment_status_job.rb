class ShiprocketSyncShipmentStatusJob < ApplicationJob
  queue_as :default

  def perform(shipment_id)
    shipment = ShiprocketShipment.find_by(id: shipment_id)
    return unless shipment
    return if shipment.awb_code.blank? && shipment.sr_shipment_id.blank?

    service = ShiprocketService.new

    tracking_data =
      if shipment.awb_code.present?
        service.track_by_awb(shipment.awb_code)
      else
        service.track_by_shipment_id(shipment.sr_shipment_id)
      end

      Rails.logger.info("Shiprocket tracking data for shipment #{shipment.id}: #{tracking_data.inspect}")
      status_text = tracking_data.dig('tracking_data', 'shipment_status') ||
                  tracking_data['current_status']

    shipment.last_shiprocket_status = status_text
    shipment.last_synced_at         = Time.current

    new_status = ShiprocketStatusMapper.from_tracking(tracking_data, status_text)

    if new_status
      shipment.status = new_status
      order = shipment.order
      begin
        order.update_status!(new_status, notes: "Updated by Shiprocket tracking API: #{status_text}")
      rescue => e
        Rails.logger.error("Failed to update order #{order.id} via tracking job: #{e.message}")
      end
    end

    shipment.save!
  rescue ShiprocketService::Error => e
    Rails.logger.error("Shiprocket tracking error for shipment #{shipment_id}: #{e.message}")
  rescue => e
    Rails.logger.error("ShiprocketSyncShipmentStatusJob failed for shipment #{shipment_id}: #{e.message}")
    raise
  end
end
