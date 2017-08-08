class Genre < ApplicationRecord
  has_many :review_genres
  has_many :reviews, through: :review_genres

  validates_presence_of :genre_name
  validates :genre_name, length: { minimum: 3 }
end
