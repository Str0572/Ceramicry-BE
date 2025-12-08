require 'httparty'
require 'openssl'
require 'base64'

class CashfreeService
  include HTTParty

  class Error < StandardError; end

  def initialize
    @app_id = ENV['CASHFREE_APP_ID']
    @secret_key = ENV['CASHFREE_SECRET_KEY']
    env = (ENV['CASHFREE_ENV'] || 'sandbox').to_s.downcase
    @base = ENV['CASHFREE_BASE'].presence
    # @base = ENV['CASHFREE_BASE'].presence || (env == 'production' ? 'https://api.cashfree.com/pg' : 'https://sandbox.cashfree.com/pg')

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

    headers = default_headers

    response = self.class.post("/orders", body: payload.to_json, headers: headers, timeout: 20)
    data = response.parsed_response
    unless response.success?
      raise Error, "#{data['message']} (code: #{data['code']})" if data['code']
    end

    unless data['payment_session_id'].present?
      raise Error, "Cashfree did not return payment_session_id"
    end

  data
  end

  def verify_payment(order_number)
    headers = default_headers

    response = self.class.get("/orders/#{order_number}", headers: headers, timeout: 20)
    data = response.parsed_response
    data
  end

  def verify_signature(signature:, payload:)
    return false if signature.blank? || payload.blank?
    digest = OpenSSL::HMAC.digest("sha256", @secret_key, payload)
    base64_signature = Base64.strict_encode64(digest)
    secure_compare(base64_signature, signature)
  end

  private

  def default_headers
    {
      "Content-Type"      => "application/json",
      "x-client-id"       => @app_id,
      "x-client-secret"   => @secret_key,
      "x-api-version"     => "2022-09-01"
    }
  end

  def secure_compare(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"
    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }
    res == 0
  end
end
