module Api
  class SubscribesController < ApplicationController
    skip_before_action :authenticate_request

    def create
      subscribe = Subscribe.new(create_params)
      if subscribe.save
        render json: subscribe, status: :created
      else
        render json: { errors: subscribe.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def create_params
      params.permit(:email)
    end
  end
end
