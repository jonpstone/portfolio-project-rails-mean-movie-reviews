class Review < ApplicationRecord
  belongs_to :writer, inverse_of: :reviews
  has_many :review_genres
  has_many :genres, through: :review_genres
  has_many :comments, as: :commentable

  validates_presence_of :title, :content, :year, :date_published
  validates_uniqueness_of :title, :content
  validates :content, length: { minimum: 500 }
  validates :title, length: { minimum: 2 }
  validates :year, length: { is: 4 }
end
