class CommentsController < ApplicationController
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params)
    @comment.author = Current.user
    authorize @comment

    if @comment.save
      redirect_to post_path(@post), notice: "댓글이 작성되었습니다."
    else
      @comments = @post.comments.recent.includes(:author)
      render "posts/show", status: :unprocessable_entity
    end
  end

  def destroy
    @comment = @post.comments.find(params[:id])
    authorize @comment
    @comment.destroy!
    redirect_to post_path(@post), notice: "댓글이 삭제되었습니다."
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
