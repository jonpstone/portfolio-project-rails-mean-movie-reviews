class CommentsController < ApplicationController
  before_action :set_review
  before_action :all_comments

  def index
    render json: @comments, layout: false
  end

  def create
    @comment = @review.comments.build(
      comments_params.merge(user_id: current_user.id)
    )
    if @comment.save
      respond_to do |format|
        format.html { render 'comments/show', layout: false }
        format.json { render json: @comment }
      end
    else
      render @review
    end
  end

  private

    def all_comments
      @comments = @review.comments
    end

    def set_review
      @review = Review.find(params[:review_id])
    end

    def comments_params
      params.require(:comment).permit(:content)
    end
end
