module Api
  class ShiprocketWebhooksController < ActionController::API
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_request

    def receive
      raw = request.raw_post
      payload = JSON.parse(raw) rescue {}

      Rails.logger.info("Shiprocket Webhook Received: #{payload}")

      data = payload["data"] || {}

      awb_code    = data["awb_code"] || payload["awb_code"]
      shipment_id = data["shipment_id"] || payload["shipment_id"]
      status_text = data["current_status"]&.to_s
      event_id    = data["current_status_id"].to_i rescue nil

      if awb_code.blank? && shipment_id.blank?
        return render json: { error: "Missing AWB or Shipment ID" }, status: 400
      end

      shipment = ::ShiprocketShipment.find_by(awb_code: awb_code) ||
                  ::ShiprocketShipment.find_by(sr_shipment_id: shipment_id)

      return render json: { message: "Shipment not found" } if shipment.nil?

      shipment.last_shiprocket_status = status_text
      shipment.last_synced_at = Time.current

      order = shipment.order
      new_status = ShiprocketStatusMapper.from_webhook(event_id, status_text)

      if new_status
        shipment.status = new_status
        begin
          order.update_status!(new_status, notes: "Updated by Shiprocket webhook: #{status_text}")
        rescue => e
          Rails.logger.error("Shiprocket webhook status update failed for order #{order.id}: #{e.message}")
        end
      end

      shipment.save!

      render json: { success: true }
    rescue => e
      Rails.logger.error("Shiprocket webhook processing failed: #{e.message}")
      render json: { success: false, error: e.message }, status: :internal_server_error
    end
  end
end