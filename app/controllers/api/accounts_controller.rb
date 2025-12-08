module Api
  class AccountsController < ApplicationController
    skip_before_action :authenticate_request, only: [:signup, :forgot_password, :otp_confirmation, :reset_user_password]
    before_action :find_user, only: [:show, :update, :destroy]
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

    def destroy
      @account = Account.with_deleted.find_by(id: params[:id])

      return render json: { message: "Account not found" }, status: :not_found unless @account

      unless params[:password].present?
        return render json: { message: "Password is required" }, status: :unprocessable_entity
      end
      
      unless @account.authenticate(params[:password])
        return render json: { message: "Incorrect password" }, status: :unauthorized
      end

      if @account.destroy
        render json: { message: "Account deleted successfully" }, status: :ok
      else
        render json: { message: "Unable to delete account" }, status: :unprocessable_entity
      end
    end

    def forgot_password
      if params[:email].blank?
        return render json: { errors: [ 'Email is required' ] }, status: :unprocessable_entity
      end

      user = Account.find_by(email: params[:email].to_s.downcase)
      unless user
        return render json: {
          message: "If an account with this email exists, an OTP has been sent."
        }, status: :ok
      end

      if user.otp_sent_at.present? && user.otp_sent_at > 1.minute.ago
        return render json: {
          errors: ["OTP already sent recently. Please wait a minute before requesting another."]
        }, status: :too_many_requests
      end

      otp = rand(100000..999999)
      if user.update(otp_pin: otp.to_s, otp_sent_at: Time.current, reset_password_token: nil, reset_password_sent_at: nil)
        NotificationMailer.with(account: user).email_otp_send.deliver_now

        render json: {
          message: "OTP sent successfully."
        }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def otp_confirmation
      if params[:otp].blank? || params[:email].blank?
        return render json: { errors: ['Email and OTP are required'] }, status: :unprocessable_entity
      end

      user = Account.find_by(email: params[:email].to_s.downcase)
      return render json: { errors: ['Invalid email or OTP'] }, status: :unprocessable_entity unless user

      if user.otp_pin.blank? || user.otp_sent_at.blank? || user.otp_sent_at < 5.minutes.ago
        return render json: { errors: ['OTP expired. Please request a new one.'] }, status: :unprocessable_entity
      end

      unless user.otp_pin.to_s == params[:otp].to_s
        return render json: { errors: ['Invalid OTP'] }, status: :unprocessable_entity
      end

      reset_token = SecureRandom.hex(32)
      user.update!(
        reset_password_token: reset_token,
        reset_password_sent_at: Time.current,
        otp_pin: nil,
        otp_sent_at: nil
      )

      render json: {
        message: 'OTP verified successfully.'
      }, status: :ok
    end

    def reset_user_password

      if params[:email].blank? || params[:new_password].blank? || params[:password_confirmation].blank?
        return render json: { errors: ['New password and confirm password are required'] }, status: :unprocessable_entity
      end

      user = Account.find_by(email: params[:email].downcase)
      return render json: { errors: ['Invalid email'] }, status: :unprocessable_entity unless user

      if user.reset_password_token.blank? || user.reset_password_sent_at < 5.minutes.ago
        return render json: { errors: ['Reset request expired. Try again.'] }, status: :unprocessable_entity
      end

      if user.update(
        password: params[:new_password],
        password_confirmation: params[:password_confirmation],
        reset_password_token: nil,
        reset_password_sent_at: nil
      )
        render json: {
          message: ['Password reset successfully']
        }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
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
