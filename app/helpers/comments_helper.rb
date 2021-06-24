module CommentsHelper
  def comments_count(source, view, app, admin=false, user_id=nil)
    if admin
      Comment.where(blocked_by_id: nil).query_by(source, view, app).size
    else
      Comment.where(user_id: user_id, admin_only: true).query_by(source, view, app).size + Comment.where(blocked_by_id: nil, admin_only: false).query_by(source, view, app).size
    end
  end

  def preview_text(text)
    len = Rails.application.config.preview_comment_text_length
    if text.length > len
      text.first(len) + ' ...'
    else 
      text
    end 
  end

  def get_index_comments_path(source, view, app)
    query_str = "?"
    query_str += "source_id=#{source.id}" if source
    query_str += "&view_id=#{view.id}" if view
    query_str += "&app=#{app}" if app

    comments_path + query_str
  end

  def get_comment_bubble_id(source, view, app)
    id = ""
    id += "#{source.id}-" if source
    id += "#{view.id}-" if view
    id += "#{app}-" if app

    id + "comment"
  end
end
