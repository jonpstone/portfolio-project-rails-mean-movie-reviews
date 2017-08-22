class WritersController < ApplicationController
  before_action :authorize_user, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_writer, only: [:show, :edit, :update, :destroy]

  def index
    @writers = Writer.order(:name)
  end

  def show
  end

  def new
    @writer = Writer.new
    @writer.reviews.build
  end

  def create
    @writer = Writer.new(writer_params)
    if @writer.save
      redirect_to @writer, notice: "Critic created"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @writer.update(writer_params.except(:reviews_attributes))
      redirect_to @writer, notice: "Critic profile updated"
    else
      render :edit
    end
  end

  def destroy
    @writer.destroy
    redirect_to home_admin_area_path, alert: "Writer deleted"
  end

  private

    def set_writer
      @writer = Writer.find(params[:id])
    end

    def writer_params
      params.require(:writer).permit(:name, :publication, :bio,
      reviews_attributes: [:title, :year, :date_published, :content,
      :writer_id, {genre_ids: []}, :image, :excerpt, :banner])
    end
end
