class User < ApplicationRecord
  has_secure_password
  validates_presence_of :username, :email
  validates_uniqueness_of :username, :email
  validates :password,  presence: { on: :create },
                        length: { minimum: 6, allow_nil: true },
                        confirmation: true
  validates :password_confirmation, presence: true, if: '!password.nil?'

  def self.find_or_create_by_omniauth(auth_hash)
    random_pass = SecureRandom.hex
    self.where(email: auth_hash["info"]["email"]).first_or_create do |user|
      user.username = auth_hash["info"]["name"]
      user.provider = auth_hash["provider"]
      user.password = random_pass
      user.password_confirmation = random_pass
    end
  end
end
