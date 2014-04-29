class Stats
  def post_count
    Post.count
  end

  def comment_count
    Comment.count
  end

  def tag_count
    Post.tags_on(:tags).size
  end
end
