module NavigationHelper
  def page_links_for_navigation
    link = Struct.new(:name, :url)
    [link.new("Home", root_path),
     link.new("Archives", archives_path)] +
      Page.order('title').collect { |page| link.new(page.title, page_path(page.slug)) }
  end

  def category_links_for_navigation
    link = Struct.new(:name, :url)
    @popular_tags ||= Post.tag_counts
      .sort_by(&:taggings_count)
      .reverse
      .map {|tag|
        link.new tag.name, posts_path(:tag => tag.name)
      }
  end

  def class_for_tab(tab_name, index)
    classes = []
    classes << 'current' if "admin/#{tab_name.downcase}" == params[:controller]
    classes << 'first'   if index == 0
    classes.join(' ')
  end
end
