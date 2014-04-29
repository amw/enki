class Admin::DashboardController < Admin::BaseController
  def show
    @posts = Post
      .order(published_at: :desc)
      .includes(:tags)
      .limit(8)
    @comment_activity = CommentActivity.find_recent
    @stats            = Stats.new
  end
end
