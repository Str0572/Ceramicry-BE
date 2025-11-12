require 'httparty'
require 'openssl'

class CashfreeService
  include HTTParty

  class Error < StandardError; end

  def initialize
    @app_id = ENV['CASHFREE_APP_ID']
    @secret_key = ENV['CASHFREE_SECRET_KEY']
    env = (ENV['CASHFREE_ENV'] || 'sandbox').to_s.downcase
    @base = ENV['CASHFREE_BASE'].presence || (env == 'production' ? 'https://sandbox.cashfree.com/pg' : 'https://sandbox.cashfree.com/pg')

    self.class.base_uri @base
    raise Error, "Cashfree credentials missing for env=#{env}" if @app_id.blank? || @secret_key.blank?
  end

  def create_order(order:, return_url:)
    total_amount = order.total_amount.to_f.round(2)

    payload = {
      order_id: order.order_number,
      order_amount: total_amount,
      order_currency: 'INR',
      customer_details: {
        customer_id: order.account_id.to_s,
        customer_name: order.account&.full_name || 'Customer',
        customer_email: order.account&.email,
        customer_phone: order.account&.mobile || ''
      },
      order_meta: {
        return_url: return_url
      }
    }

    headers = {
      "Content-Type" => "application/json",
      "x-client-id" => @app_id,
      "x-client-secret" => @secret_key,
      "x-api-version" => "2022-09-01"
    }

    response = self.class.post("/orders", body: payload.to_json, headers: headers, timeout: 20)
    data = response.parsed_response
    unless response.success?
      raise Error, data['message'] || "Cashfree order creation failed"
    end

    unless data['payment_session_id'].present?
      raise Error, "Cashfree did not return payment_session_id"
    end

  data
  end

  def verify_payment(order_number)
    headers = {
      "Content-Type" => "application/json",
      "x-client-id" => @app_id,
      "x-client-secret" => @secret_key,
      "x-api-version" => "2022-09-01"
    }

    response = self.class.get("/orders/#{order_number}", headers: headers, timeout: 20)
    data = response.parsed_response
    data
  end

  def verify_signature(signature:, payload:)
    return false if signature.blank? || payload.blank?
    digest = OpenSSL::HMAC.hexdigest('sha256', @secret_key.to_s, payload.to_s)
    secure_compare(digest, signature.to_s)
  end

  private

  def secure_compare(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"
    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }
    res == 0
  end
end
