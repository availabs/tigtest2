module ViewsHelper

  def action_item(icon, name, view, action=nil, role=nil, title)
    action = name if action.nil?
    url = '#'
    if view
      if action == 'new_map'
        url = "/v2/views/#{view.id}/map"
      if action == 'new_table'
        url = "/v2/views/#{view.id}/table"
      elsif action == 'add_comment'
        url = new_comment_path + "?view_id=#{view.id}"
      elsif action == 'edit_metadata'
        url = add_role_to_params(role, edit_view_path(view))
      elsif action == 'view_metadata'
        url = "#{view_path(view)}/metadata"
      elsif action == 'access'
        url = view.access_controls.empty? ? new_access_control_path(view: view.id) : edit_access_control_path(view.access_controls.find_by(role: [nil, 'public', 'agency']), view: view.id)
      elsif action == 'watch'
        url = watch_view_path(view)
      elsif action == 'delete'
        url = view_path(view)
      elsif action == 'upload'
        url = new_upload_path(view: view.id)
      elsif action == 'copy'
        url = add_role_to_params(role, new_view_path(view_id: view.id, source_id: view.source.id), true) unless role == "agency_admin"
      elsif view.has_action?(name) || (action == 'edit')
        url = "#{view_path(view)}/#{action}"
      end
    end
    count_bubble_tags = (render partial: 'comments/count_bubble', locals: {source: @view.source, view: @view, app: name})
    link_to ("<i class=\"fa #{icon}\"></i> #{name.titleize}" + count_bubble_tags).html_safe, url, class: "list-group-item btn-lg btn-block", title: title, style: "display: inline-block; text-align: center;", method: (:delete if action == 'delete'), data: {confirm: ("Are you sure?" if action == 'delete')}
  end

  def table_dropdown_item(view, name, role=nil, user=nil)
    case name
    when "edit_metadata"
      url = add_role_to_params(role, edit_view_path(view))
    when "view_metadata"
      url = view_path(view)
    when "watch"
      has_watch = !user.watches.find_by(view: view).nil?
      url = has_watch ? unwatch_view_path(view) : watch_view_path(view)
      unwatch = true if has_watch
    when "upload"
      url = new_upload_path(view: view.id)
    when "copy"
      url = add_role_to_params(role, new_view_path(view_id: view.id, source_id: view.source.id), true) unless role == "agency_admin"
    else
      url = "#{view_path(view)}/#{name}"
    end
    name = "unwatch" if unwatch
    link_to name.titleize, url, method: (:delete if name == 'delete'), data: {confirm: ("Are you sure?" if name == 'delete')}
  end

  def has_year_slider(view)
    view && view.data_model == DemographicFact
  end

  def compute_data_end_points(view, start_or_end)
    result = start_or_end == "start" ? view.data_starts_at : view.data_ends_at
    data_model = view.data_model

    unless result || data_model.nil? || data_model.blank?
      if data_model.column_names.include?('day_of_week') # LinkSpeedFact, SpeedFact
        
        if start_or_end == "start"
          min_months = data_model.min_months
          result = "#{min_months.values[0]}/#{min_months.keys[0]}"
        else
          max_months = data_model.max_months
          result = "#{max_months.values[-1]}/#{max_months.keys[-1]}"
        end

      elsif data_model.column_names.include?('month')
        
        if start_or_end == "start"
          result = data_model.where("view_id = ? and month > 0", view).minimum(:month)
        else
          result = data_model.where("view_id = ? and month > 0", view).maximum(:month)
        end

      elsif data_model.column_names.include?('year') # CountFact, DemographicFact, RtpProject, UpwpProject
        
        if start_or_end == "start"
          result = data_model.where("view_id = ? and year > 0", view).minimum(:year)
        else
          result = data_model.where("view_id = ? and year > 0", view).maximum(:year)
        end

      else # ComparativeFact, TipProject, UpwpRelatedContract
        nil
      end
    end
    (result.is_a?(String) ? Date.parse(result).strftime("%b %Y") : result) rescue nil
  end

  def filter_actions(user, view)
    return [] if view.nil?
    all_actions = Action.all_names
    base_actions = Action.base_actions
    guest_actions = Action.guest_actions

    if user
      if user.has_role?(:admin)
        all_actions
      elsif user.has_role?(:librarian)
        view.librarians.include?(user) ? ((base_actions << ["edit_metadata", "upload", "copy"]).flatten) : base_actions
      elsif user.has_role?(:contributor)
        view.contributors.include?(user) ? ((base_actions << ["edit_metadata", "upload", "copy"]).flatten) : base_actions
      elsif user.has_role?(:agency_admin)
        view.source.agency == user.agency ? (base_actions << "edit_metadata") : base_actions
      elsif user.has_any_role?(:agency_user, :public)
        base_actions
      else
        guest_actions
      end
    else
      guest_actions
    end
  end

  def add_role_to_params(role, path, copy=false)
    connecting_symbol = copy ? "&" : "?"

    case role
    when 'contributor'
      path + "#{connecting_symbol}contributor=true"
    when 'librarian'
      path + "#{connecting_symbol}librarian=true"
    when 'agency_admin'
      path + "#{connecting_symbol}agency_admin=true"
    when 'admin'
      path + "#{connecting_symbol}admin=true"
    else
      path
    end
  end

  def bonsai_source_css(source)
    Comment.find_by(source: source) ? '' : 'margin-left:30px;'
  end

  def bonsai_view_css(view)
    Comment.find_by(view: view) ? '' : 'margin-left:20px;'
  end

  def watches_exist_for_user?(user, source_or_view)
    if source_or_view.class == Source
      !user.watches.find_by(source: source_or_view).nil?
    else
      !user.watches.find_by(view: source_or_view).nil?
    end
  end
end
