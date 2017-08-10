class HomeController < ApplicationController
  def index
    @reviews = Review.all.order("created_at DESC").first(5)
  end

  def admin_area
    @reviews = Review.order(:title)
    @writers = Writer.order(:name)
    @genres = Genre.order(:genre_name)
    return head(:forbidden) unless current_user.admin?
  end
end
