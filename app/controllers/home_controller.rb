class HomeController < ApplicationController
  before_action :redirection, only: :admin_area

  def index
    if logged_in?
      @reviews = Review.all
    else
      redirect_to signin_path
    end
  end

  def admin_area
    @reviews = Review.order(:title)
    @writers = Writer.order(:name)
    @genres = Genre.order(:genre_name)
  end
end
