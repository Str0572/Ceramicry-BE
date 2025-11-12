module Api
  module Agents
    class SessionsController < ActionController::Base
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      def login
        agent = DeliveryAgent.find_by(email: params[:email])
        if agent&.authenticate(params[:password]) && agent.active?
          token = JwtToken.encode(agent_id: agent.id)
          render json: { id: agent.id, name: agent.full_name, token: token, message: 'Agent logged in.' }
        else
          render json: { errors: ['Invalid credentials'] }, status: :unauthorized
        end
      end
    end
  end
end



