class CommentsController < ApplicationController
  before_action :set_review

  def index
    @comments = @review.comments
    render 'comments/index', layout: false
  end

private

    def set_review
      @review = Review.find(params[:review_id])
    end

    def comments_params
      params.require(:comment).permit(:content)
    end
end
