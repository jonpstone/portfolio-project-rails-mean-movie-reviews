class CommentsController < ApplicationController
  before_action :set_review

  def index
    @comments = @review.comments
      render 'index.html', layout: false}
    end
  end

  def create
    @comment = @review.comments.build(comments_params)
    if @comment.save
      render 'create.js', :layout => false
    else
      render "posts/show"
    end
  end

private

    def set_review
      @review = Post.find(params[:review_id])
    end

    def comments_params
      params.require(:comment).permit(:content)
    end
end
