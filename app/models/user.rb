class User < ApplicationRecord
  has_secure_password
  validates_presence_of :username, :email
  validates_uniqueness_of :username, :email
  validates :password,  presence: { on: :create },
                        length: { minimum: 6, allow_nil: true },
                        confirmation: true
  validates :password_confirmation, presence: true, if: '!password.nil?'
end
