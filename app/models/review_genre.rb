class ReviewGenre < ApplicationRecord
  belongs_to :review
  belongs_to :genre
end
