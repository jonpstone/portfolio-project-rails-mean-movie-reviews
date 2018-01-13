class ReviewSerializer < ActiveModel::Serializer
  attributes :id, :content, :title, :image, :writer_id, :year, :date_published
end
