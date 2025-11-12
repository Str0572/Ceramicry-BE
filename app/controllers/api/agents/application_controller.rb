module Api
  module Agents
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :null_session

      before_action :authenticate_agent!

      private

      def authenticate_agent!
        token = request.headers['Token']
        token = token.split(' ').last if token
        begin
          decoded = JwtToken.decode(token)
          @current_agent = DeliveryAgent.find_by(id: decoded[:agent_id])
          render json: { errors: ['Agent not found or inactive'] }, status: :unauthorized unless @current_agent&.active?
        rescue JWT::DecodeError
          render json: { errors: ['Invalid token'] }, status: :unauthorized
        end
      end

      def current_agent
        @current_agent
      end
    end
  end
end



