class Account < ApplicationRecord
  has_secure_password

  has_many :addresses, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :offer_usages, dependent: :destroy
  has_many :offers, through: :offer_usages
  has_many :order_statuses, dependent: :destroy

  enum :account_type, { customer: 0, delivery_partner: 1}
  
  validates :account_type, inclusion: { in: %w[customer delivery_partner] }
  validates :full_name, presence: true
  validates :full_name, format: { with: /\A[a-zA-Z ]+\z/, message: "only allows letters" }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
  validates :password, format: { 
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+\z/,
    message: "must include uppercase, lowercase, digit, and special character"
  }, allow_blank: true, if: :password_required?

  validate :passwords_match, if: :password_required?

  # after_create :send_email_confirmation
  after_create :create_default_cart
  after_update :create_default_cart

  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end

  private

  def passwords_match
    return if password == password_confirmation
    errors.add(:password_confirmation, "doesn't match password")
  end

  def send_email_confirmation
    self.update(status: true)
    AccountMailer.with(account: self).account_confirmation_email.deliver_now
  end

  def create_default_cart
    create_cart unless cart.present?
  end
end