class Review < ApplicationRecord
  belongs_to :writer, inverse_of: :reviews
  has_many :review_genres
  has_many :genres, through: :review_genres
  has_many :comments

  validates_presence_of :title, :content, :year, :date_published
  validates_uniqueness_of :title, :content
  validates :content, length: { minimum: 500 }
  validates :title, length: { minimum: 2 }
  validates :year, length: { is: 4 }

  mount_uploader :image, ImageUploader
  mount_uploader :banner, BannerUploader

  def self.latest_review
    order("created_at DESC").limit(1).first
  end

  def self.second_latest_review
    order("created_at DESC").offset(1).limit(1).first
  end

  def self.third_latest_review
    order("created_at DESC").offset(2).limit(1).first
  end

  def self.fourth_latest_review
    order("created_at DESC").offset(3).limit(1).first
  end

  def self.fifth_latest_review
    order("created_at DESC").offset(4).limit(1).first
  end

  def self.sixth_latest_review
    order("created_at DESC").offset(5).limit(1).first
  end

  def self.ordered
    order(:title).all
  end

  def self.search(query)
    where("title LIKE :query OR content LIKE :query", query: "%#{query}%")
  end

  def as_json(options = {})
    super(options.merge(include: [:user, comments: {include: :user}]))
  end
end
