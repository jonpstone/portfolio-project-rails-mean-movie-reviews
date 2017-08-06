class HomeController < ApplicationController
  before_action :authenticate_user!, only: :admin_area

  def index
    @reviews = Review.all
  end

  def admin_area
    @reviews = Review.order(:title)
    @writers = Writer.order(:name)
    @genres = Genre.order(:name)
    return head(:forbidden) unless current_user.admin?
  end
end
