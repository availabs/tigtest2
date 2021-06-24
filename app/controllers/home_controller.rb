class HomeController < ApplicationController
  def index
    @sources = AccessControl.viewable_sources(current_user)
    top_sources_by_view = View.order(view_count: :desc).map{ |view| view.source }.uniq
    @top_8 = top_sources_by_view.map{ |s| s if @sources.include?(s) }.compact.sort_by(&:name)
    @relevant_sources = @top_8

    @expanded = []
    if params[:expand].nil?
      @show_catalog = true
      @show_recent = true
      @show_snap = user_signed_in?
      @show_contributions = user_signed_in? && current_user.has_any_role?(:admin, :agency_admin)
    else
      case params[:expand]
      when 'catalog'
        @show_catalog = true
        @expand_catalog = true
      when 'recent'
        @show_recent = true
        @expand_recent = true
        add_breadcrumb 'Recent Activity'
      when 'snap'
        @show_snap = user_signed_in?
        @expand_snap = true
        add_breadcrumb 'My Snapshots'
      when 'contributions'
        @show_contributions = user_signed_in? && current_user.has_any_role?(:admin, :agency_admin)
        @expand_contributions = true
        add_breadcrumb 'New Contributions'
      end
    end
    @dashboard = true

    @dashboard_limit = current_user ? current_user.recent_activity_dashboard_limit : 3
    @expanded_limit = current_user ? current_user.recent_activity_expanded_limit : 10
    limit = [@dashboard_limit, @expanded_limit].max
    viewable_sources = AccessControl.viewable_sources(current_user).sort_by(&:updated_at).reverse
    viewable_views = []
    viewable_sources.each { |source| viewable_views += AccessControl.viewable_views(current_user, source) }
    viewable_comments = []
    if current_user
      if current_user.has_role?(:admin)
        viewable_sources.each { |source| viewable_comments += Comment.where(blocked_by_id: nil).query_by(source, nil, nil) }
        viewable_views.each { |view| viewable_comments += Comment.where(blocked_by_id: nil).query_by(view.source, view, nil) }
      else
        viewable_sources.each do |source| 
          viewable_comments += Comment.where(blocked_by_id: nil, admin_only: false).query_by(source, nil, nil)
          viewable_comments += Comment.where(blocked_by_id: nil, user_id: current_user.id).query_by(source, nil, nil)
        end

        viewable_views.each do |view|
          viewable_comments += Comment.where(blocked_by_id: nil, admin_only: false).query_by(view.source, view, nil)
          viewable_comments += Comment.where(blocked_by_id: nil, user_id: current_user.id).query_by(view.source, view, nil)
        end
      end
    else
      viewable_sources.each { |source| viewable_comments += Comment.where(blocked_by_id: nil).query_by(source, nil, nil) }
      viewable_views.each { |view| viewable_comments += Comment.where(blocked_by_id: nil).query_by(view.source, view, nil) }
    end

    if current_user.nil?
      @recents = viewable_sources.first(limit)
      @recents += viewable_views.first(limit)
      @recents += viewable_comments.uniq
    else
      if current_user.has_role?(:admin)
        @recents = View.includes(:user).order(updated_at: :desc).limit(limit).to_a
        @recents += Comment.includes(:user).order(updated_at: :desc).limit(limit).to_a
        @recents += Source.includes(:user).order(updated_at: :desc).limit(limit).to_a
      else
        @recents = viewable_sources.first(limit)
        @recents += viewable_views.first(limit)
        @recents += viewable_comments.uniq
      end
    end

    if user_signed_in?
      @snap_limit = current_user.snapshot_limit
      @snapshots = Snapshot.where(user: current_user)
      viewable_snapshots = []
      Snapshot.all.each{ |s| viewable_snapshots << s if (s.viewers.include?(current_user) || s.published == true) }
      @snapshots += viewable_snapshots
      @snapshots = @snapshots.uniq
    end

    @new_contributions = viewable_sources.sort_by(&:created_at).reverse
    @new_contributions += viewable_views.sort_by(&:created_at).reverse
    viewable_views.each { |view| @new_contributions += view.uploads.sort_by(&:created_at).reverse }

    if request.xhr?
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    respond_to do |format|
      format.html { render }
      format.js   # index.js.erb
    end
  end
end
