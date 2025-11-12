module Api
  class PaymentsController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_request, except: [:cashfree_webhook]

    def cashfree_webhook
      raw = request.raw_post
      signature = request.headers['x-webhook-signature'] || request.headers['X-Webhook-Signature']
      service = CashfreeService.new
      unless service.verify_signature(signature: signature, payload: raw)
        Rails.logger.warn "Cashfree webhook signature mismatch"
        return head :unauthorized
      end
      payload = JSON.parse(raw) rescue {}
      order_number = payload.dig('data', 'order', 'order_id') || payload['order_id']
      payment_status = payload.dig('data', 'payment', 'payment_status') || payload['payment_status']
      return head :ok unless order_number && payment_status

      order = Order.find_by(order_number: order_number)
      if order && payment_status&.downcase == 'success'
        order.update!(payment_status: 'paid')
        order.update_status!('confirmed', notes: 'Payment confirmed via Cashfree webhook.') unless order.status != 'pending'
      end
      head :ok
    end

    def verify_payment
      order_number = params[:id]
      service = CashfreeService.new
      verify_response = service.verify_payment(order_number)
      render json: verify_response
    end
  end
end


