module Api
  module Agents
    class OrdersController < ApplicationController
      before_action :set_order, only: [:show, :update_status, :add_location, :upload_proof]

      def index
        orders = Order.where(delivery_agent_id: current_agent.id).recent
        render json: { data: ActiveModelSerializers::SerializableResource.new(orders, each_serializer: OrderSerializer) }
      end

      def show
        render json: { data: OrderSerializer.new(@order).serializable_hash }
      end

      def update_status
        new_status = params[:status].to_s
        unless %w[out_for_delivery delivered].include?(new_status)
          return render json: { errors: ['Invalid status for agent'] }, status: :unprocessable_entity
        end

        if @order.update_status!(new_status, notes: params[:notes])
          render json: { data: OrderSerializer.new(@order).serializable_hash, message: 'Status updated' }
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def add_location
        location = @order.order_locations.create(
          delivery_agent: current_agent,
          latitude: params[:latitude],
          longitude: params[:longitude],
          recorded_at: Time.current
        )
        if location.persisted?
          render json: { data: OrderLocationSerializer.new(location).serializable_hash }
        else
          render json: { errors: location.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def upload_proof
        if params[:proof].present?
          @order.proof_of_delivery.attach(params[:proof])
          render json: { message: 'Proof uploaded' }
        else
          render json: { errors: ['No file provided'] }, status: :unprocessable_entity
        end
      end

      private

      def set_order
        @order = Order.where(delivery_agent_id: current_agent.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { errors: ['Order not found'] }, status: :not_found
      end
    end
  end
end



