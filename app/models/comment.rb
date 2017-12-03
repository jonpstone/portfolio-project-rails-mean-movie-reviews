class Comment < ApplicationRecord
  belongs_to :review
  belongs_to :user

  validates :body, length: { minimum: 3 }
end
