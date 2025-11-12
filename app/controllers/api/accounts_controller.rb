module Api
  class AccountsController < ApplicationController
    skip_before_action :authenticate_request, only: [:signup, :forgot_password, :otp_confirmation, :reset_user_password]
    before_action :find_user, only: [:show, :update, :reset_user_password]
    before_action :authorize_access, only: [:index]

    def index
      @users = Account.all
      if @users.exists?
        render json: {
          data: ActiveModelSerializers::SerializableResource.new(@users, each_serializer: AccountSerializer),
          message: 'User list fetched successfully'
        }, status: :ok
      else
        render json: { message: "No Data Found." }, status: :not_found
      end
    end

    def signup
      user = Account.new(account_params)
      if user.save
        token = JwtToken.encode(user_id: user.id)
        render json: {
          message: 'Signup successful.',
          token: token,
          account: user.slice(:id, :full_name, :email)
        }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def show
      render json: {
        data: AccountSerializer.new(@user).serializable_hash,
        message: 'User Details'
      }, status: :ok
    end

    def update
      if @user.update(update_params)
        render json: {
          data: AccountSerializer.new(@user).serializable_hash,
          message: 'User details updated successfully'
        }, status: :ok
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def forgot_password
      if params[:email].blank?
        return render json: { errors: [{ otp: 'Email is required' }] }, status: :unprocessable_entity
      end

      @user = Account.find_by(email: params[:email])
      return render json: { errors: [{ otp: 'User not found' }] }, status: :not_found unless @user

      if @user.update(otp_pin: rand(1000..9999), otp_sent_at: Time.current)
        AccountMailer.with(account: @user).email_otp_send.deliver_now
        render json: {
          data: { id: @user.id, email: @user.email, otp_pin: @user.otp_pin },
          message: "OTP sent successfully"
        }, status: :ok
      else
        render json: { errors: @user.errors }, status: :unprocessable_entity
      end
    end

    def otp_confirmation
      if params[:otp].blank? || params[:id].blank?
        return render json: { errors: [{ otp: 'ID and OTP code are required' }] }, status: :unprocessable_entity
      end

      @user = Account.find_by(id: params[:id])
      return render json: { errors: "Invalid ID" }, status: :not_found unless @user

      if @user.otp_pin.to_s == params[:otp].to_s
        render json: { data: { id: @user.id, email: @user.email }, message: "OTP confirmed successfully" }, status: :ok
      else
        render json: { errors: "Invalid OTP." }, status: :unprocessable_entity
      end
    end

    def reset_user_password
      if params[:new_password].blank? || params[:password_confirmation].blank?
        return render json: { errors: [{ password: 'New password and confirm password are required' }] }, status: :unprocessable_entity
      end

      if @user.otp_pin.present? && @user.otp_sent_at.present?
        if @user.update(password: params[:new_password], password_confirmation: params[:password_confirmation], otp_pin: nil, otp_sent_at: nil)
          render json: {
            data: AccountSerializer.new(@user).serializable_hash,
            message: ['Password reset successfully']
          }, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { errors: [{ id: 'OTP not generated or expired' }] }, status: :unprocessable_entity
      end
    end

    def change_password
      if @current_user.authenticate(params[:current_password])
        if @current_user.update(password: params[:new_password], password_confirmation: params[:confirm_password])
          render json: { message: "Password updated successfully", status: 200 }, status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { errors: "Incorrect current password" }, status: :unprocessable_entity
      end
    end

    private

    def account_params
      params.require(:account).permit(:full_name, :email, :password, :password_confirmation, :mobile)
    end

    def update_params
      params.require(:account).permit(:full_name, :mobile, :email)
    end

    def find_user
      @user = Account.find_by(id: params[:id])
      unless @user
        render json: {
          message: "User with id #{params[:id]} doesn't exist"
        }, status: :not_found
      end
    end
  end
end
