class Watch < ActiveRecord::Base
  belongs_to :user
  belongs_to :source
  belongs_to :view
  attr_accessible(:user_id, :source_id, :view_id, :last_seen_at, :last_triggered_at)

  def self.trigger(obj, comment=nil)
    update_last_triggered_at(obj, comment)
    comment.nil? ? send_metadata_email(obj) : send_comment_email(obj, comment)
  end

  def self.update_last_seen_at(obj, user)
    if obj.class == Source
      Watch.where(source: obj).each{ |w| w.update_attribute('last_seen_at', Time.now) if w.user == user }
    else
      Watch.where(view: obj).each{ |w| w.update_attribute('last_seen_at', Time.now) if w.user == user }
    end
  end

  def self.update_last_triggered_at(obj, comment=nil)
    time = comment.nil? ? Time.now : comment.created_at
    if obj.class == Source
      if comment.nil?
        Watch.where(source: obj).each{ |w| w.update_attribute('last_triggered_at', time) unless w.user == obj.rows_updated_by }
      else
        Watch.where(source: obj).each{ |w| w.update_attribute('last_triggered_at', time) unless w.user == comment.user }
      end
    else
      if comment.nil?
        Watch.where(view: obj).each{ |w| w.update_attribute('last_triggered_at', time) unless w.user == obj.rows_updated_by }
      else
        Watch.where(view: obj).each{ |w| w.update_attribute('last_triggered_at', time) unless w.user == comment.user }
      end
    end
  end

  def self.send_metadata_email(obj)
    if obj.class == Source
      Watch.where(source: obj).each{ |w| WatchMailer.metadata_email(w.user, obj).deliver unless w.user == obj.rows_updated_by }
    else
      Watch.where(view: obj).each{ |w| WatchMailer.metadata_email(w.user, obj).deliver unless w.user == obj.rows_updated_by }
    end
  end

  def self.send_comment_email(obj, comment)
    if obj.class == Source
      Watch.where(source: obj).each{ |w| WatchMailer.comment_email(w.user, obj, comment).deliver unless w.user == comment.user }
    else
      Watch.where(view: obj).each{ |w| WatchMailer.comment_email(w.user, obj, comment).deliver unless w.user == comment.user }
    end
  end

  def user
    super || User.default if user_id
  end

  def triggered?
    if last_triggered_at.nil?
      false
    else
      last_triggered_at > last_seen_at ? true : false
    end
  end
end
