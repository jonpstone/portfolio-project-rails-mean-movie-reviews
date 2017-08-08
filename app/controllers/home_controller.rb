class HomeController < ApplicationController
  def index
    @reviews = Review.all
  end

  def admin_area
    @reviews = Review.order(:title)
    @writers = Writer.order(:name)
    @genres = Genre.order(:genre_name)
    return head(:forbidden) unless current_user.admin?
  end
end
