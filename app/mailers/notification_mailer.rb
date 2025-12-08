class NotificationMailer < ApplicationMailer
  default from: ENV['MAIL_FROM'] || 'no-reply@ceramicry.com'

  def email_otp_send
    @account = params[:account]
    @otp = @account.otp_pin

    mail(to: @account.email, subject: 'Your password reset OTP')
  end

  def order_created(user, order)
    @user = user
    @order = order
    mail(to: @user.email, subject: "Your Order ##{@order.order_number} has been placed!")
  end

  def order_status_updated(user, order, status)
    @user = user
    @order = order
    @status = status
    mail(to: @user.email, subject: "Order ##{@order.order_number} is now #{status.humanize}")
  end

  def account_created(user)
    @user = user
    mail(to: @user.email, subject: 'Welcome to Ceramicry! Your account is created')
  end

  def password_updated(user)
    @user = user
    mail(to: @user.email, subject: 'Your password has been updated')
  end

  def new_offer_created(user, offer)
    @user = user
    @offer = offer
    mail(to: @user.email, subject: "New Offer: #{@offer.code}")
  end
end
