class CommentsController < ApplicationController
  before_action :enforce_ownership, only: [:show, :edit]
  before_action :set_comment, only: [:show, :edit, :update, :block, :unblock, :destroy]

  def new
    @comment = Comment.new
    setup_commentable_params

    setup_comment_breadcrumbs
    add_breadcrumb 'Add Comment'
  end

  def create
    @comment = Comment.new(comment_params)
    @comment.user = current_user

    if @comment.save
      flash[:notice] = "Comment posted."
      if @comment.app
        if @comment.app == "metadata"
          redirect_to view_path(@comment.view)
        else
          redirect_to "#{view_path(@comment.view.id)}/#{@comment.app}"
        end
      else
        redirect_to sources_path
      end
      triggering_obj = @comment.view ? @comment.view : @comment.source
      Watch.trigger(triggering_obj, @comment)
    else
      @source = @comment.source
      @view = @comment.view 
      @app = @comment.app
      render action: "new"
    end
  end

  def index
    setup_commentable_params

    authorize! :index, Comment
    
    @all_comments = Comment.all
    @agency_comments = User.where(agency_id: current_user.agency_id).map(&:comments).flatten
    @my_comments = Comment.where(user: current_user)
    @user = User.find(params[:user]) if params[:user]
    @unsortables = [9]
    @invisibles = [7]
    
    if current_user.has_any_role?(:admin, :agency_admin)
      @table_type = 'admin'

      if params[:user]
        if @user == current_user
          @comments = @my_comments
          @table_type = 'my_comments'
          @admin_header = @agency_admin_header = 'My Comments'
          @unsortables = [10,11]
          @invisibles = [2,7]
        else
          @comments = Comment.where(user: @user)
          @admin_header = @agency_admin_header = "#{user_name_or_email(@user)}'s Comments"
        end
      elsif @source || @view || @app
        @comments = Comment.where(blocked_by_id: nil).query_by(@source, @view, @app)
        @admin_header = @agency_admin_header = "'#{@view ? @view.name : @source.name}' Comments"
      else
        @comments = current_user.has_role?(:admin) ? @all_comments : @agency_comments
        @admin_header = 'All Comments'
        @agency_admin_header = 'Agency Comments'
      end

    else

      if params[:user]
        if @user == current_user
          @comments = @my_comments
          @table_type = 'my_comments'
          @nonadmin_header = "My Comments"
          @table_type = 'my_comments'
          @unsortables = [10,11]
          @invisibles = [2,7]
        else
          # SHOULD NON-ADMINS BE ABLE TO SEE OTHER SPECIFIC USERS' COMMENTS?
          redirect_to :back, alert: "You are not permitted to view this user's comments."
        end
      elsif @source || @view || @app
        my_admin_only = Comment.where(user_id: current_user.id, admin_only: true).query_by(@source, @view, @app)
        other_comments = Comment.where(blocked_by_id: nil, admin_only: false).query_by(@source, @view, @app)
        @comments = (my_admin_only + other_comments).sort_by(&:created_at).reverse!
        @table_type = 'nonadmin'
        @nonadmin_header = "'#{@view ? @view.name : @source.name}' Comments"
        @unsortables = []
      else
        @comments = @my_comments
        @table_type = 'my_comments'
        @nonadmin_header = "My Comments"
      end

    end

    setup_comment_breadcrumbs
    add_breadcrumb 'Comments'
  end

  def show
    user = @comment.user.nil? ? "Deleted User" : @comment.user.display_name
    add_breadcrumb "#{user} Comment", @comment
    Watch.update_last_seen_at((@comment.view.nil? ? @comment.source : @comment.view), current_user) if user_signed_in?
  end

  def edit
  end

  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html do
          redirect_to(comment_path(@comment))
          flash[:notice] = "Comment updated."
        end
      else
        format.html { render action: "edit", alert: "There was a problem updating your comment." }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def block
    @comment.update_attribute(:blocked_by_id, current_user.id)
    render json: @comment.errors
  end

  def unblock
    @comment.update_attribute(:blocked_by_id, nil)
    render json: @comment.errors
  end

  def destroy
    if @comment.destroy
      redirect_to comments_path(user: current_user)
      flash[:notice] = "Comment deleted."
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def setup_comment_breadcrumbs
    if @view && @app 
      add_breadcrumb @app.titleize, view_path(@view) + "/#{@app}"
    end
  end

  def comment_params
    params.require(:comment).permit(:subject, :text, :source_id, :view_id, :app, :admin_only)
  end

  def setup_commentable_params
    @view = View.find(params[:view_id]) if params[:view_id]
    if @view
      @source = @view.source
    elsif params[:source_id]
      @source = Source.find(params[:source_id])
    end
    @app = ((params[:app] == "view_metadata" || params[:app] == "edit_metadata") ? "metadata" : params[:app])
  end

  def enforce_ownership
    @comment = Comment.find(params[:id])
    if user_signed_in?
      if !(@comment.view ? (AccessControl.viewable_views(current_user, @comment.source).include?(@comment.view) if AccessControl.viewable_sources(current_user).include?(@comment.source)) : AccessControl.viewable_sources(current_user).include?(@comment.source)) # && !current_user.has_any_role?(:agency_user, :agency_admin, :admin) || current_user.has_any_role?(:agency_user, :agency_admin, :admin)
        redirect_to root_path, alert: "You are not permitted to view this comment."
      end
    else
      redirect_to root_path, alert: "You must be logged in to view comments"
    end
  end
end
