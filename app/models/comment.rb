class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  has_many :comments, as: :commentable

  validates :body, length: { minimum: 3 }
end
