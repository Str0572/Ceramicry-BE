class Subscribe < ApplicationRecord
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, uniqueness: { case_sensitive: false, message: "has already been taken"}, format: { with: EMAIL_REGEX }
end
