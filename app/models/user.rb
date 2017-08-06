class User < ApplicationRecord
  validates_presence_of :hometown, :username, :email
  validates_uniqueness_of :username, :email
  validates :username, :hometown, length: { in: 3..25 }
  validates :password,  presence: { on: :create },
                        length: { minimum: 6, allow_nil: true },
                        confirmation: true
  validates :password_confirmation, presence: true, if: '!password.nil?'

  has_secure_password
end
