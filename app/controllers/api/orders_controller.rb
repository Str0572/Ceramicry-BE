module Api
  class OrdersController < ApplicationController
    before_action :authenticate_request
    before_action :set_order, only: [:show, :cancel, :track, :add_notes, :request_return]
    
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
      render json: {
        data: {
          order: OrderSerializer.new(@order).serializable_hash.merge({
            milestones: milestones,
            can_cancel: @order.can_be_cancelled?,
            can_return: @order.can_be_returned?,
            estimated_delivery: @order.estimated_delivery
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

    private

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
