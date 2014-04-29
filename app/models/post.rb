class Post < ActiveRecord::Base
  DEFAULT_LIMIT = 15

  acts_as_taggable

  has_many                :comments, :dependent => :destroy
  has_many                :approved_comments, :class_name => 'Comment'

  before_validation       :generate_slug
  before_validation       :set_dates
  before_save             :apply_filter

  validates               :title, :slug, :body, :presence => true

  validate                :validate_published_at_natural

  def validate_published_at_natural
    if published_at_natural.present? && !published?
      errors.add("published_at_natural", "Unable to parse time")
    end
  end

  attr_accessor :minor_edit
  def minor_edit
    @minor_edit ||= "1"
  end

  def minor_edit?
    self.minor_edit == "1"
  end

  def published?
    published_at?
  end

  attr_accessor :published_at_natural
  def published_at_natural
    @published_at_natural ||= published_at.send_with_default(:strftime, '', "%Y-%m-%d %H:%M")
  end

  class << self
    def build_for_preview(params)
      post = Post.new(params)
      post.generate_slug
      post.set_dates
      post.apply_filter
      post.tag_list = params[:tag_list]
      post
    end

    def by_permalink year, month, day, slug
      date = [year, month, day].map(&:to_i).join "-"
      day_start = Time.zone.parse(date).midnight
      day_end = day_start + 24.hours
      self
        .where(slug: slug)
        .where("published_at BETWEEN ? AND ?", day_start, day_end)
        .order(published_at: :desc)
    rescue ArgumentError # Invalid time
      raise ActiveRecord::RecordNotFound
    end

    def find_all_grouped_by_month
      posts = find(
        :all,
        :order      => 'posts.published_at DESC',
        :conditions => ['published_at < ?', Time.now]
      )
      month = Struct.new(:date, :posts)
      posts.group_by(&:month).inject([]) {|a, v| a << month.new(v[0], v[1])}
    end
  end

  def destroy_with_undo
    transaction do
      undo = DeletePostUndo.create_undo(self)
      self.destroy
      return undo
    end
  end

  def month
    published_at.beginning_of_month
  end

  def apply_filter
    self.body_html = EnkiFormatter.format_as_xhtml(self.body)
  end

  def set_dates
    self.edited_at = Time.now if self.edited_at.nil? || !minor_edit?
    unless self.published_at_natural.nil?
      if self.published_at_natural.blank?
        self.published_at = nil
      elsif new_published_at = Chronic.parse(self.published_at_natural)
        self.published_at = new_published_at
      end
    end
  end

  def denormalize_comments_count!
    update approved_comments_count: approved_comments.count
  end

  def generate_slug
    self.slug = self.title.dup if self.slug.blank?
    self.slug.slugorize!
  end
end
