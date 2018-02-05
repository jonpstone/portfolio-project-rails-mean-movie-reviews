class ReviewsController < ApplicationController
  before_action :authorize_user, except: [:index, :show, :search]
  before_action :set_new_writer, only: [:new, :edit]
  before_action :set_review, only: [:show, :edit, :update, :destroy]
  before_action :set_writer, only: :index

  def index
    @reviews = Review.where(writer_id: params[:writer_id])
    render json: @reviews
  end

  def show
    @comments = @review.comments
    @comment = Comment.new
  end

  def new; end

  def create
    @review = Review.new(review_params)
    if @review.save
      redirect_to @review, notice: 'Review created'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @review.update(review_params)
      redirect_to @review, notice: 'Review updated'
    else
      render :edit
    end
  end

  def destroy
    @review.destroy
    redirect_to home_admin_area_path, alert: 'Review deleted'
  end

  def search
    if params[:search]
      @reviews = Review.search(params[:search]).order('created_at DESC')
    else
      @reviews = Review.all.order('created_at DESC')
    end
    render :search
  end

  private

    def review_params
      params.require(:review).permit(:title, :year, :date_published, :content,
      :writer_id, {genre_ids: []}, :image, :excerpt, :banner)
    end

    def set_review
      @review = Review.find(params[:id])
    end

    def set_writer
      @writer = Writer.find(params[:writer_id])
    end

    def set_new_writer
      @review = Review.new(writer_id: params[:writer_id])
    end
end
