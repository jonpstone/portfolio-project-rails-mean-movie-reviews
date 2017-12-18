class CommentsController < ApplicationController
  before_action :set_review

  def index
    @comments = @review.comments
    respond_to do |format|
      format.html {render 'index.html', layout: false}
      format.js {render 'index.js', layout: false}
    end
  end

  def create
    @comment = @review.comments.build(comments_params)
    if @comment.save
      render 'comments/show', layout: false
    else
      render "posts/show"
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
