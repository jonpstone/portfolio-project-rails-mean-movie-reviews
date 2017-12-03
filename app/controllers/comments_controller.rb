class CommentsController < ApplicationController
before_action :set_review

  def index
    @comments = @review.comments
  end

  def new
    @comment = Comment.new
  end

  def create
    @comment = @commentable.comments.new comment_params
    if logged_in?
      if @comment.save
        redirect_to :back, notice: 'Your comment was successfully posted'
      else
        redirect_to :back, error: "An error occured, comment not posted"
      end
    else
      redirect_to :back, alert: "You must sign up or log in to comment!"
    end
  end

  private

    def comment_params
      params.require(:comment).permit(:body)
    end

    def set_review
      @review = Review.find(params[:review_id])
    end
end
