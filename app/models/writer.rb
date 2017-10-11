class Writer < ApplicationRecord
  has_many :reviews, inverse_of: :writer, dependent: :destroy

  validates_uniqueness_of :name
  validates_presence_of :name, :publication, :bio
  validates :name, :publication, length: { in: 3..25 }
  validates :bio, length: { in: 100..3000 }

  def latest_review
    self.reviews.order("created_at DESC").first
  end

  def reviews_attributes=(reviews_attributes)
    reviews_attributes.each do |i, review_attributes|
      self.reviews.build(review_attributes)
    end
  end
end
