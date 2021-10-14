class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_action_and_controller

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message.gsub('this', 'that')
  end

  add_breadcrumb 'Catalog', :root_path

  def set_action_and_controller
    @controller_tag = params[:controller].gsub('/', '_')
    @action_tag = params[:action]
    # indicate special cases, e.g. guest user on home page
    if (@controller_tag == 'home') && (@action_tag == 'index')
      if current_user.nil?
        @special = '_guest'
      elsif !params[:expand].blank?
        @special = "_#{params[:expand]}"
      end
    elsif (@controller_tag == 'comments') && (@action_tag == 'index') && params[:user]
      @special = "_user"
    elsif (@controller_tag == 'sources') && (@action_tag == 'index')
      @special = "_contributor" if params[:contributor_id]
      @special = "_librarian" if params[:librarian_id]
    else
      @special = ''
    end
  end
  
  def system_usage_report
    @user_count = User.count
    @active_user_count = User.where("last_sign_in_at >= ?", 1.month.ago).size
    @active_user_login_count = User.where("last_sign_in_at >= ?", 1.month.ago).map(&:sign_in_count).reduce(:+)
    @agency_count = Agency.count
    @source_count = Source.count
    @view_count = View.count
    @upload_count = Upload.count
    @download_count = View.all.map(&:download_count).reduce(:+)
    @snapshot_count = Snapshot.count
    @comment_count = Comment.count
    @study_area_count = StudyArea.count
    @watch_count = Watch.count
    @sysadmin_count = User.with_role(:admin).size
    @agency_admin_count = User.with_role(:agency_admin).size
    @contributor_count = User.with_role(:contributor).size
    @librarian_count = User.with_role(:librarian).size

    sources = AccessControl.viewable_sources(current_user)
    top_sources_by_view = View.order(view_count: :desc).map{ |view| view.source }.uniq
    @top_sources_by_view = top_sources_by_view.map{ |s| s if sources.include?(s) }.compact.first(8)
    @top_sources_by_comment = Source.select("sources.id, sources.name, count(comments.id) AS source_comments_count").joins(:comments).group("sources.id").order("source_comments_count DESC").limit(8)
    @top_sources_by_watch = Source.select("sources.id, sources.name, count(watches.id) AS source_watches_count").joins(:watches).group("sources.id").order("source_watches_count DESC").limit(8)

    @top_views_by_view = View.order(view_count: :desc).limit(8)
    @top_views_by_comment = View.select("views.id, views.name, views.data_levels, views.value_columns, count(comments.id) AS view_comments_count").joins(:comments).group("views.id").order("view_comments_count DESC").limit(8)
    @top_views_by_watch = View.select("views.id, views.name, views.data_levels, views.value_columns, count(watches.id) AS view_watches_count").joins(:watches).group("views.id").order("view_watches_count DESC").limit(8)
    @top_views_by_download = View.order(download_count: :desc).limit(8)
    @top_views_by_upload = View.select("views.id, views.name, views.data_levels, views.value_columns, count(uploads.id) AS view_uploads_count").joins(:uploads).group("views.id").order("view_uploads_count DESC").limit(8)
    @top_views_by_snapshot = View.select("views.id, views.name, views.data_levels, views.value_columns, count(snapshots.id) AS view_snapshots_count").joins(:snapshots).group("views.id").order("view_snapshots_count DESC").limit(8)

    @donut_data = @top_views_by_view.map {|v| [v.name, v.view_count] }.unshift(['View', 'No. of Visits***'])
    @bar_data = View.all.order(download_count: :desc).limit(8).map { |v| [v.name, v.download_count] }.unshift(['View', 'No. of Downloads'])
    @bar_2_data = @top_views_by_upload.map { |v| [v.name, v.uploads.size] }.unshift(['View', 'No. of Uploads'])
  end

  def system_change_report
  end

  def user_activity_report
    @users = User.with_any_role(:admin, :agency_admin, :agency_user, :contributor, :librarian).sort_by{ |u| u.display_name.downcase }
    @user = User.find(params[:user]) if params[:user]

    if @user
      @comment_count = Comment.where(user: @user).size
      @watches_count = Watch.where(user: @user).size
      @snapshot_count = Snapshot.where(user: @user).size
      @study_area_count = StudyArea.where(user: @user).size
      @comments_by_source = @user.comments.map{|c| [c.source.name, Comment.where(user_id: c.user_id, source_id: c.source_id).size] }.uniq.unshift(["Source", "Comment Count"])
      @comments_by_view = @user.comments.map{|c| [c.view.name, Comment.where(user_id: c.user_id, view_id: c.view_id).size] if c.view }.uniq.compact.unshift(["View", "Comment Count"])
      @snapshots_by_source = Snapshot.where(user: @user).map{|s| [s.view.source.name, s.view.source.views.map{|v| v.snapshots.where(user_id: s.user_id)}.flatten.size] }.uniq.unshift(["Source", "Snapshot Count"])
      @snapshots_by_view = Snapshot.where(user: @user).map{|s| [s.view.name, Snapshot.where(user_id: s.user_id, view_id: s.view_id).size] if s.view }.uniq.compact.unshift(["View", "Snapshot Count"])
      @watches_by_source = @user.watches.map{|w| [w.source.name, Watch.where(user: w.user, source: w.source).size] if w.source }.uniq.compact.unshift(["Source", "Watches Count"])
      @watches_by_view = @user.watches.map{|w| [w.view.name, Watch.where(user: w.user, view: w.view).size] if w.view }.uniq.compact.unshift(["View", "Watch Count"])
      @uploads_by_view = @user.uploads.map{|u| [u.view.name, Upload.where(user: u.user, view: u.view).size] if u.view }.uniq.compact.unshift(["View", "Upload Count"])
      @uploads_by_status = @user.uploads.map{|u| [u.status.capitalize, Upload.where(status: u.status).size] }.uniq.compact.unshift(["View", "Status"])
      @uploads_by_year = @user.uploads.map{|u| [u.updated_at.strftime("%Y"), Upload.where("extract(year from updated_at) = ? AND user_id = ?", u.updated_at.strftime("%Y"), u.user_id).size] }.uniq.compact.unshift(["View", "Year"])
      @uploads_by_month = @user.uploads.map{|u| [u.updated_at.strftime("%B"), Upload.where("extract(month from updated_at) = ? AND user_id = ?", u.updated_at.strftime("%m"), u.user_id).size] }.uniq.compact.unshift(["View", "Month"])
    end
  end

  def alert_admins_to_contribution(obj)
    case obj
    when Upload
      if obj.view
        agency = obj.view.source.agency
      else
        agency = obj.source.agency
      end
    when View
      agency = obj.source.agency if obj.source
    else
      agency = obj.agency
    end

    all_admins = User.with_role(:admin)
    all_admins += User.with_role(:agency_admin).where(agency: agency) if agency
    all_admins.uniq.map{ |admin| AdminMailer.new_contribution_email(admin, obj).deliver unless obj.user == admin }
  end

  def user_name_or_email(user)
    user.display_name.blank? ? user.email : user.display_name
  end

  def user_array(user)
    [user_name_or_email(user), user.id]
  end

  def configure_multiselect_data(hash, role)
    admin_count = User.where("agency_id IS NOT NULL").with_role(:admin).size
    hash["Admin"] = [] if admin_count > 0

    users_sorted_by_agency = User.where("agency_id IS NOT NULL").with_any_role(:admin, role.to_sym).sort_by(&:agency_id)
    users_sorted_by_agency.each do |user|
      if user.has_role?(:admin)
        hash["Admin"] << [user_name_or_email(user), user.id]
      else
        if hash["#{user.agency.name}"]
          hash["#{user.agency.name}"] << [user_name_or_email(user), user.id]
        else
          hash["#{user.agency.name}"] = []
          hash["#{user.agency.name}"] << [user_name_or_email(user), user.id]
        end
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :display_name
  end

end
