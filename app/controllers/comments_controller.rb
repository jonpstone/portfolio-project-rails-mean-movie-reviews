class CommentsController < ApplicationController
  before_action :set_review

  def index
    @comments = @review.comments
    render json: @comments
  end

  def create
    @comment = @review.comments.build(comments_params)
    if @comment.save
      render 'comments/show', layout: false
    else
      render " "
    end
  end

  private

    def set_review
      @review = Review.find(params[:review_id])
    end

    def comments_params
      params.require(:comment).permit(:content)
    end
end
