class Comment < ActiveRecord::Base
  include Gravtastic
  gravtastic :author_email,
             :size => 40,
             :default => Enki::Config.default[:url] + '/assets/openid_icon.png'

  DEFAULT_LIMIT = 15

  attr_accessor         :openid_error
  attr_accessor         :openid_valid
  attr_accessor         :honeypot_email
  attr_accessor         :honeypot_logger_info

  belongs_to            :post

  before_save           :apply_filter, :validate_honeypot
  after_save            :denormalize
  after_destroy         :denormalize

  after_create :send_notification

  validates             :author, :body, :post, :presence => true
  validate :open_id_error_should_be_blank

  def open_id_error_should_be_blank
    errors.add(:base, openid_error) unless openid_error.blank?
  end

  # Validate hidden anti-spam email textfield.
  def validate_honeypot
    unless self.honeypot_email.blank?
      blank_all_fields
      logger.info "Spambot detected: #{self.honeypot_logger_info.inspect}"
      return false
    end
  end

  def apply_filter
    self.body_html = Lesstile.format_as_xhtml(self.body, :code_formatter => Lesstile::CodeRayFormatter)
  end

  def blank_all_fields
    attrs = {}
    self.attribute_names.each {|attr| attrs[attr] = ""}
    self.attributes = attrs
    logger.debug(self.attributes)
  end

  def blank_openid_fields
    self.author_url = ""
    self.author_email = ""
  end

  def requires_openid_authentication?
    return false unless author

    !!(author =~ %r{^https?://} || author =~ /\w+\.\w+/)
  end

  def trusted_user?
    false
  end

  def user_logged_in?
    false
  end

  def approved?
    true
  end

  def denormalize
    self.post.denormalize_comments_count!
  end

  def destroy_with_undo
    undo_item = nil
    transaction do
      self.destroy
      undo_item = DeleteCommentUndo.create_undo(self)
    end
    undo_item
  end

  # Delegates
  def post_title
    post.title
  end

  def send_notification
    CommentMailer.notification(self).deliver
  end

  class << self
    def protected_attribute?(attribute)
      [:author, :body].include?(attribute.to_sym)
    end

    def new_with_filter(params)
      comment = Comment.new(params)
      comment.created_at = Time.now
      comment.apply_filter
      comment
    end

    def build_for_preview(params)
      comment = Comment.new_with_filter(params)
      if comment.requires_openid_authentication?
        comment.author_url = comment.author
        comment.author     = "Your OpenID Name"
      end
      comment
    end
  end
end
