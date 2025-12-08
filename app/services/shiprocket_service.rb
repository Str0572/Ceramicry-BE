require 'httparty'
MOCK_MODE = ENV["SHIPROCKET_MOCK"] == "true"

class ShiprocketService
  include HTTParty
  base_uri 'https://apiv2.shiprocket.in/v1/external'

  class Error < StandardError; end

  def initialize
    @email    = ENV['SHIPROCKET_EMAIL']
    @password = ENV['SHIPROCKET_PASSWORD']
    @pickup_location = ENV['SHIPROCKET_PICKUP_LOCATION']
    raise Error, "Shiprocket credentials missing" if @email.blank? || @password.blank?
  end

  def auth_token
    return "FAKE_TOKEN_123" if MOCK_MODE
    response = self.class.post(
      '/auth/login',
      headers: { 'Content-Type' => 'application/json' },
      body: { email: @email, password: @password }.to_json
    )
    data = response.parsed_response
    raise Error, (data['message'] || 'Shiprocket auth failed') unless response.success? && data['token'].present?

    data['token']
  end

  def authorized_headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{auth_token}"
    }
  end

  def create_order_for(order)
    payload = build_order_payload(order)

    if MOCK_MODE
      fake_response = {
        "order_id" => order.order_number,
        "shipment_id" => rand(100000..999999).to_s,
        "message" => "Mock order created successfully"
      }
      Rails.logger.warn("MOCK SHIPROCKET ORDER RESPONSE: #{fake_response.to_json}")
      return [fake_response, fake_response]
    end

    response = self.class.post(
      '/orders/create/adhoc',
      headers: authorized_headers,
      body: payload.to_json,
      timeout: 30
    )
    data = response.parsed_response
    unless response.success?
      raise Error, (data['message'] || 'Shiprocket order creation failed')
    end

    [data, data]
  end

  def assign_courier(shipment_id)

    if MOCK_MODE
      mock = {
        "status_code" => 1,
        "awb_assign_status" => 1,
        "response" => {
          "data" => {
            "awb_code" => "MOCKAWB#{rand(1000..9999)}",
            "courier_id" => "MOCK_COURIER"
          }
        }
      }
      Rails.logger.warn("MOCK SHIPROCKET COURIER ASSIGN RESPONSE: #{mock.to_json}")
      return mock
    end

    payload = {
      shipment_id: shipment_id,
      courier_id: nil
    }

    response = self.class.post(
      '/courier/assign/awb',
      headers: authorized_headers,
      body: payload.to_json,
      timeout: 30
    )

    data = response.parsed_response
    Rails.logger.error("COURIER ASSIGN RESPONSE: #{data.inspect}")

    unless response.success?
      raise Error, (data['message'] || 'Shiprocket courier assignment failed')
    end

    data
  end

  def track_by_awb(awb_code)

    if MOCK_MODE
      return {
        "tracking_data" => {
          "track_url" => "https://mock-shiprocket-track/#{awb_code}",
          "shipment_status" => "In Transit (Mock)"
        }
      }
    end
    raise Error, "AWB code is required" if awb_code.blank?

    response = self.class.get(
      "/courier/track/awb",
      headers: authorized_headers,
      query: { awb: awb_code },
      timeout: 30
    )

    data = response.parsed_response
    unless response.success?
      raise Error, (data['message'] || 'Shiprocket tracking by AWB failed')
    end

    data
  end

  def track_by_shipment_id(shipment_id)
    raise Error, "Shipment ID is required" if shipment_id.blank?

    response = self.class.get(
      "/courier/track/shipment",
      headers: authorized_headers,
      query: { shipment_id: shipment_id },
      timeout: 30
    )

    data = response.parsed_response
    unless response.success?
      raise Error, (data['message'] || 'Shiprocket tracking by shipment_id failed')
    end

    data
  end

  private

  def build_order_payload(order)
    shipping = order.shipping_address
    account  = order.account

    # payment_method = order.payment_method == 'cash_on_delivery' ? 'COD' : 'Prepaid'
    payment_method = 'Prepaid'
    payload={
      order_id:       order.order_number,
      order_date:     order.created_at.strftime('%Y-%m-%d %H:%M'),
      pickup_location: @pickup_location,
      channel_id:     '',
      comment:        order.notes.to_s,

      billing_customer_name:  shipping.name,
      billing_last_name:      '',
      billing_address:        shipping.address_line1,
      billing_address_2:      shipping.address_line2.to_s,
      billing_city:           shipping.city,
      billing_pincode:        shipping.pincode,
      billing_state:          shipping.state,
      billing_country:        shipping.country,
      billing_email:          account.email,
      billing_phone:          shipping.phone,

      shipping_customer_name: shipping.name,
      shipping_last_name: '',
      shipping_address: shipping.address_line1,
      shipping_address_2: shipping.address_line2.to_s,
      shipping_city: shipping.city,
      shipping_pincode: shipping.pincode,
      shipping_state: shipping.state,
      shipping_country: shipping.country,
      shipping_email: account.email,
      shipping_phone: shipping.phone,

      shipping_is_billing: true,

      order_items: order.order_items.map do |item|
        {
          name:          item.product_name || item.product.name,
          sku:           item.variant&.sku || item.product.sku,
          units:         item.quantity,
          selling_price: item.unit_price.to_f,
          discount:      0,
          tax:           item.tax_amount.to_f,
          hsn:           "69111010"
        }
      end,

      payment_method: payment_method,
      sub_total:      order.subtotal.to_f,
      length:         ENV.fetch('SHIPROCKET_DEFAULT_LENGTH', 10).to_f,
      breadth:        ENV.fetch('SHIPROCKET_DEFAULT_BREADTH', 10).to_f,
      height:         ENV.fetch('SHIPROCKET_DEFAULT_HEIGHT', 10).to_f,
      weight:         ENV.fetch('SHIPROCKET_DEFAULT_WEIGHT', 0.5).to_f
    }
    Rails.logger.info "Shiprocket Payload: #{payload.to_json}"
    Rails.logger.info "Final Payload to Shiprocket: #{payload.to_json}"
    payload
  end
end
