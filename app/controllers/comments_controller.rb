class CommentsController < ApplicationController
before_action :find_commentable

  def new
    @comment = Comment.new
  end

  def create
    @comment = @commentable.comments.new comment_params
    if logged_in?
      if @comment.save
        redirect_to :back, notice: 'Your comment was successfully posted'
      else
        redirect_to :back, notice: "An error occured, comment not posted"
      end
    else
      redirect_to :back, notice: "You must sign up or log in to comment!"
    end
  end

  private

    def comment_params
      params.require(:comment).permit(:body)
    end

    def find_commentable
      @commentable = Comment.find_by_id(params[:comment_id]) if params[:comment_id]
      @commentable = Review.find_by_id(params[:review_id]) if params[:review_id]
    end
end
