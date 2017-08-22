class HomeController < ApplicationController
  def index
    @reviews = Review.order("created_at ASC").last(5)
  end

  def admin_area
    @reviews = Review.order(:title)
    @writers = Writer.order(:name)
    @genres = Genre.order(:genre_name)
  end
end
