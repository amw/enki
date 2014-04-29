class PostsController < ApplicationController
  def index
    @tag = params[:tag]
    @posts = Post
      .where('published_at < ?', Time.zone.now)
      .order(published_at: :desc)
      .includes(:tags)
      .limit(Post::DEFAULT_LIMIT)

    @posts = @posts.tagged_with @tag if @tag

    respond_to do |format|
      format.html
      format.atom { render :layout => false }
    end
  end

  def show
    @post = Post
      .by_permalink(params[:year], params[:month], params[:day], params[:slug])
      .includes(:approved_comments, :tags)
      .first!
    @comment = Comment.new
  end
end
