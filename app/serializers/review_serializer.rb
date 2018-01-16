class ReviewSerializer < ActiveModel::Serializer
  attributes :id, :content, :title, :image, :writer_id, :year, :date_published
  belongs_to :genre, serializer: ReviewGenreSerializer, if: -> { false }
end
