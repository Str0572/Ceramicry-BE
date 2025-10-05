module Api
  class AuthController < ApplicationController
    skip_before_action :authenticate_request
  
    def login
      @user = Account.find_by(email: params[:email])
      if @user&.authenticate(params[:password])
        token = JwtToken.encode(user_id: @user.id)
        render json: {
            id: @user.id,
            name: @user.full_name,
            token: token,
            message: "User successfully logged in."
          }, status: :ok
      else
        render json: { errors: 'Invalid credentials' }, status: :unauthorized
      end
    end
  end
end