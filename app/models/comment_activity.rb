class CommentActivity
  attr_accessor :post

  def initialize(post)
    self.post = post
  end

  def comments
    @comments ||= post.approved_comments.order(created_at: :desc).limit 5
  end

  def self.find_recent
    Post.select('posts.*, max(comments.created_at), comments.post_id')
      .group('comments.post_id, posts.' + Post.column_names.join(', posts.'))
      .joins('INNER JOIN comments ON comments.post_id = posts.id')
      .order('max(comments.created_at) desc')
      .limit(5)
    .collect { |post| CommentActivity.new(post) }
    .sort_by { |activity| activity.comments.first.created_at }
    .reverse
  end
end
