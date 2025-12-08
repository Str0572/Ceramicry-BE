require 'ostruct'
module Api
  class OrdersController < ApplicationController
    before_action :authenticate_request
    before_action :set_order, only: [:show, :cancel, :track, :add_notes, :request_return]
    skip_before_action :verify_authenticity_token
    
    def index
      @orders = current_user.orders.includes(:shipping_address, :billing_address, :order_items, :order_statuses)
                           .recent
                           .page(params[:page])
                           .per(params[:per_page] || 10)

      if @orders.any?
        render json: {
          data: ActiveModelSerializers::SerializableResource.new(@orders, each_serializer: OrderSerializer),
          pagination: {
            current_page: @orders.current_page,
            total_pages: @orders.total_pages,
            total_count: @orders.total_count,
            per_page: @orders.limit_value
          },
          message: 'Orders fetched successfully'
        }, status: :ok
      else
        render json: { message: "No orders found" }, status: :ok
      end
    end

    def show
      render json: {
        data: OrderSerializer.new(@order).serializable_hash,
        message: 'Order details fetched successfully'
      }, status: :ok
    end

    def checkout
      unless current_user.cart&.cart_items&.any?
        return render json: { errors: ["Cart is empty"] }, status: :unprocessable_entity
      end

      unless params[:shipping_address_id].present? && params[:billing_address_id].present?
        return render json: { errors: ["Shipping and billing addresses are required"] }, status: :unprocessable_entity
      end

      payment_method = params[:payment_method]

      case payment_method
      when 'cash_on_delivery'
        handle_cod_checkout
      when 'online_payment'
        handle_cashfree_checkout
      else
        render json: { errors: ["Invalid payment method"] }, status: :unprocessable_entity
      end
    end

    def cancel
      unless @order.can_be_cancelled?
        return render json: { errors: ["Order cannot be cancelled"] }, status: :unprocessable_entity
      end

      if @order.update_status!('cancelled', notes: params[:notes], created_by: current_user)
        render json: {
          data: OrderSerializer.new(@order).serializable_hash,
          message: 'Order cancelled successfully'
        }, status: :ok
      else
        render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def request_return
      unless @order.can_be_returned?
        return render json: { errors: ["Order can't be returned. Return window expired or not delivered yet."] }, status: :unprocessable_entity
      end
      if @order.update_status!('returned', notes: params[:notes], created_by: current_user)
        render json: {
          data: OrderSerializer.new(@order).serializable_hash,
          message: 'Return requested successfully'
        }, status: :ok
      else
        render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def track
      milestones = OrderStatus::MILESTONES.map do |m|
        status_record = @order.order_statuses.where(status: m[:key]).order(:created_at).first
        { 
          key: m[:key],
          name: m[:name],
          explanation: m[:explanation],
          index: m[:index],
          reached: !!status_record,
          reached_at: status_record&.created_at,
          notes: status_record&.notes
        }
      end

      sr = @order.shiprocket_shipment
      render json: {
        data: {
          order: OrderSerializer.new(@order).serializable_hash.merge({
            milestones: milestones,
            can_cancel: @order.can_be_cancelled?,
            can_return: @order.can_be_returned?,
            estimated_delivery: @order.estimated_delivery,
            shiprocket: sr.present? ? {
              awb_code: sr.awb_code,
              courier_name: sr.courier_name,
              tracking_url: sr.tracking_url,
              last_status: sr.last_shiprocket_status,
              last_synced_at: sr.last_synced_at
            } : nil
          })
        },
        message: 'Order tracking information fetched successfully'
      }, status: :ok
    end

    def add_notes
      if @order.add_status_notes(params[:notes], created_by: current_user)
        render json: {
          data: OrderSerializer.new(@order).serializable_hash,
          message: 'Notes added successfully'
        }, status: :ok
      else
        render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def status_options
      render json: {
        data: {
          order_statuses: Order.statuses.keys.map { |status| { value: status, label: status.humanize } },
          payment_statuses: Order.payment_statuses.keys.map { |status| { value: status, label: status.humanize } },
          payment_methods: Order.payment_methods.keys.map { |method| { value: method, label: method.humanize } }
        },
        message: 'Status options fetched successfully'
      }, status: :ok
    end

    def order_review
      unless current_user.cart&.cart_items&.any?
        return render json: { errors: ["Cart is empty"] }, status: :unprocessable_entity
      end

      unless params[:shipping_address_id].present? && params[:billing_address_id].present?
        return render json: { errors: ["Shipping and billing addresses are required"] }, status: :unprocessable_entity
      end

      temp_checkout = CheckoutService.new(
        account_id: current_user.id,
        shipping_address_id: params[:shipping_address_id],
        billing_address_id: params[:billing_address_id],
        payment_method: params[:payment_method] || 'cash_on_delivery',
        notes: params[:notes],
        offer_code: params[:offer_code]
      )

      unless temp_checkout.valid?
        return render json: { errors: temp_checkout.errors.full_messages }, status: :unprocessable_entity
      end

      cart_items = temp_checkout.send(:cart_items)
      items = cart_items.map do |item|
        CartItemSerializer.new(item).as_json
      end
      
      subtotal = temp_checkout.send(:cart_subtotal)
      tax_amount = temp_checkout.send(:calculate_tax)
      shipping_amount = temp_checkout.send(:calculate_shipping)

      discount_amount = 0
      if params[:offer_code].present?
        offer = Offer.find_by(code: params[:offer_code].to_s.upcase)
        if offer&.valid_for?(current_user, subtotal)
          discount_amount = offer.apply_discount(subtotal)
        end
      end

      total_amount = subtotal + tax_amount + shipping_amount - discount_amount
      render json: {
        data: {
          items: items,
          subtotal: subtotal,
          tax_amount: tax_amount,
          shipping_amount: shipping_amount,
          discount_amount: discount_amount,
          total_amount: total_amount
        },
        message: 'Order review calculated successfully'
      }, status: :ok
    end

    def cashfree_return
      order_number = params[:order_id] || params[:orderNumber]
      token = params[:token]

      decoded_payload = JwtToken.decode(token).symbolize_keys
      decoded_payload[:account_id] ||= decoded_payload.delete(:user_id)

      service = CashfreeService.new
      verified = service.verify_payment(order_number)
      order_status = verified["order_status"].to_s.downcase
      
      unless %w[paid success].include?(order_status)
        return redirect_to (ENV['FRONTEND_FAILURE_URL'] || 'https://ceramicry.netlify.app/payment-failed')
      end

      checkout_service = CheckoutService.new(
        account_id: decoded_payload[:account_id],
        shipping_address_id: decoded_payload[:shipping_address_id],
        billing_address_id: decoded_payload[:billing_address_id],
        notes: decoded_payload[:notes],
        offer_code: decoded_payload[:offer_code],
        payment_method: decoded_payload[:payment_method] || 'online_payment',
        order_number: order_number
      )

      if checkout_service.call
        created_order = checkout_service.order
        created_order.update!(payment_status: 'paid')

        render json: {
          success: true,
          order_id: created_order.id,
          order_number: created_order.order_number,
          total_amount: created_order.total_amount,
          message: 'Order created successfully'
        }, status: :ok

      else
        render json: { success: false, error: "Checkout failed" }, status: :unprocessable_entity
      end

    rescue => e
      render json: { success: false, error: e.message }, status: :internal_server_error
    end

    private

    def handle_cod_checkout
      checkout_service = CheckoutService.new(checkout_params.merge(account_id: current_user.id))
      
      if checkout_service.call
        render json: {
          data: OrderSerializer.new(checkout_service.order).serializable_hash,
          message: 'Order placed successfully'
        }, status: :created
      else
        render json: { errors: checkout_service.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def handle_cashfree_checkout
      total_amount = params[:amount].presence || params.dig(:review_data, :total_amount)
      total_amount = total_amount.to_f

      if total_amount <= 0
        return render json: { errors: ['Invalid amount'] }, status: :unprocessable_entity
      end
      temp_order_number = Order.generate_order_number
      payload = {
        account_id: current_user.id,
        shipping_address_id: params[:shipping_address_id],
        billing_address_id: params[:billing_address_id],
        notes: params[:notes],
        offer_code: params[:offer_code],
        payment_method: 'online_payment',
        expected_total_amount: total_amount,
        temp_order_number: temp_order_number
      }
      
      token = JwtToken.encode(payload)
      service = CashfreeService.new
      return_url = (ENV['FRONTEND_SUCCESS_URL'] || 'https://ceramicry.netlify.app') + "/payment-success?order_id=#{temp_order_number}&token=#{CGI.escape(token)}"

      pseudo_order = OpenStruct.new(
        total_amount: total_amount,
        order_number: temp_order_number,
        account: current_user,
        account_id: current_user.id
      )
      data = service.create_order(order: pseudo_order, return_url: return_url)
      render json: {
        data: {
          order_id: data['order_id'],
          payment_session_id: data['payment_session_id'],
          payment_link: data['payment_link'],
          order_number: temp_order_number,
          token: token,
          redirect_url: "https://ceramicry.netlify.app/payment-success?order_id=#{data['order_id']}&token=#{CGI.escape(token)}"
        },
        message: 'Cashfree session created successfully'
      }, status: :ok
    rescue CashfreeService::Error => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end

    def cashfree_return_url
      host = ENV['BACKEND_BASE_URL'] || request.base_url
      host + '/api/payments/cashfree_return'
    end

    def set_order
      @order = current_user.orders.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: ["Order not found"] }, status: :not_found
    end

    def checkout_params
      params.permit(:shipping_address_id, :billing_address_id, :payment_method, :notes, :offer_code)
    end
  end
end
