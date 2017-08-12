class ReviewsController < ApplicationController
  before_action :authorize_user, except: :show
  before_action :set_writer, only: [:new, :edit]
  before_action :set_review, only: [:show, :edit, :update, :destroy]

  def show
  end

  def new
  end

  def create
    @review = Review.new(review_params)
    if @review.save
      redirect_to @review, notice: "Review created"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to @review, notice: "Review updated"
    else
      render :edit
    end
  end

  def destroy
    @review.destroy
    redirect_to home_admin_area_path, notice: "Review deleted"
  end

  private

    def review_params
      params.require(:review).permit( :title, :year, :date_published, :content,
      :writer_id, {genre_ids: []})
    end

    def set_review
      @review = Review.find(params[:id])
    end

    def set_writer
      @review = Review.new(writer_id: params[:writer_id])
    end
end
