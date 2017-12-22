class Comment < ApplicationRecord
  belongs_to :review
  validates :content, length: { minimum: 1 }
end
