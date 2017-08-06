class GenresController < ApplicationController
  before_action :set_genre, only: [:show, :destroy]
  before_action :authorize_user, only: [:new, :create, :edit, :update, :destroy]

  def show
  end

  def new
    @genre = Genre.new
  end

  def create
    @genre = Genre.new(genre_params)
    if @genre.save
      redirect_to @genre, notice: "Genre created"
    else
      render :new
    end
  end

  def destroy
    @genre.destroy
    redirect_to home_admin_area_path, notice: "Genre deleted"
  end

  private

  def set_genre
    @genre = Genre.find(params[:id])
  end

  def genre_params
    params.require(:genre).permit(:name)
  end
end
