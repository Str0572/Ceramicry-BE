class CreateShiprocketShipmentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 10.seconds, attempts: 1

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order
    return if order.shiprocket_shipment.present?

    order.push_to_shiprocket!
  rescue ShiprocketService::Error => e
    Rails.logger.error("CreateShiprocketShipmentJob Shiprocket error for order #{order_id}: #{e.message}")
  rescue => e
    Rails.logger.error("CreateShiprocketShipmentJob failed for order #{order_id}: #{e.message}")
    raise
  end
end
