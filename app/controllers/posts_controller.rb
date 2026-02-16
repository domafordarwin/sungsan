class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy]

  def index
    authorize Post
    @posts = policy_scope(Post).pinned_first.page(params[:page]).per(15)
  end

  def show
    authorize @post
    @comments = @post.comments.recent.includes(:author)
    @comment = Comment.new
  end

  def new
    @post = Post.new
    authorize @post
  end

  def create
    @post = Post.new(post_params)
    @post.author = Current.user
    @post.parish_id = Current.parish_id
    authorize @post

    if @post.save
      redirect_to post_path(@post), notice: "게시글이 작성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @post
  end

  def update
    authorize @post
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "게시글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post
    @post.destroy!
    redirect_to posts_path, notice: "게시글이 삭제되었습니다."
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    permitted = params.require(:post).permit(:title, :body)
    permitted[:pinned] = params[:post][:pinned] if Current.user.admin?
    permitted
  end
end
