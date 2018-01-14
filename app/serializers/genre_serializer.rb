class GenreSerializer < ActiveModel::Serializer
  attributes :id, :genre_name
  has_many :reviews
end
