module Api
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session
    ERROR_CLASSES = [
        JWT::DecodeError,
        JWT::ExpiredSignature,
      ].freeze

    before_action :authenticate_request

    private

    def authenticate_request
      token = request.headers['Token']
      token = token.split(' ').last if token
      begin
        @decoded = JwtToken.decode(token)
        @current_user = Account.find_by(id: @decoded[:user_id])
      rescue ActiveRecord::RecordNotFound
        render json: { errors: ['User not found or deleted'] }, status: :not_found
      rescue *ERROR_CLASSES => exception
        handle_exception exception
      end
    end

    def handle_exception(exception)
      case exception
      when JWT::ExpiredSignature
        return render json: { errors: [token: 'Token has Expired'] }, status: :unauthorized
      when JWT::DecodeError
        return render json: { errors: [token: 'Invalid token'] }, status: :bad_request
      end
    end

    def current_user
      @current_user
    end
  end
end