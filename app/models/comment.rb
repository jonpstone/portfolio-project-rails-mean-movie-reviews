class Comment < ApplicationRecord
  belongs_to :review
  belongs_to :user

  validates :content, length: { minimum: 3 }
end
