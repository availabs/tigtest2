class SourcesController < ApplicationController
  before_action :enforce_access_controls, only: [:show, :edit]
  before_action :get_admins, only: [:new, :edit, :create]
  
  # GET /sources
  # GET /sources.json
  # GET /sources.js 
  def index

    source_id = params[:id] || session[:id]
    @sources = source_id ?  [Source.find(source_id)] : AccessControl.viewable_sources(current_user)
    @table = session[:catalog_view] == "table"
    @relevant_sources = @sources
    @description = @sources[0].description.to_s

    @contributor = params[:contributor_id] if params[:contributor_id] && !params[:contributor_id].blank?
    @librarian = params[:librarian_id] if params[:librarian_id] && !params[:librarian_id].blank?
    @admin = params[:admin] if params[:admin] && !params[:admin].blank?

    @catalog_header = @contributor ? 'My Contributions ' : (@librarian ? 'Librarian' : 'Catalog')
    @list_items_css = 'display: none;' if @table
    @table_items_css = 'display: none;' if !@table

    if user_signed_in?
      if can? :create, :source
        @new_source_link_condition = (@contributor || @librarian) || (current_user.has_role?(:admin) && !@contributor && !@librarian)

        if @contributor
          @new_source_link_text = 'Contribute Source'
          @path_to_source = new_source_path(contributor: true)
        elsif @librarian
          @new_source_link_text = 'Contribute Source'
          @path_to_source = new_source_path(librarian: true)
        elsif current_user.has_role?(:admin)
          @new_source_link_text = 'New Source'
          @path_to_source = new_source_path(admin: true)
        end
      end
    else
      @sources_viewable_as_guest = AccessControl.viewable_sources(nil).size
      @source_count = Source.count
    end

    view_id = params[:selected] || session[:selected]
    @view = View.find_by_id(view_id)
    @selected = params[:selected] || view_id
    session[:view_id] = @selected.to_i unless @selected.blank?

    @user_can_use_access_controls = @view && current_user && (
      current_user.has_role?(:admin) || 
      ( current_user.has_role?(:agency_admin) && (@view.source.agency == current_user.agency) ) || 
      ( current_user.has_role?(:contributor) && @view.contributors.include?(current_user) ) || 
      ( current_user.has_role?(:librarian) && @view.librarians.include?(current_user) )
      )
    @user_can_comment = @view && current_user && current_user.has_any_role?(:admin, :agency_user, :agency_admin, :public) && AccessControl.allow_for_comment?(current_user, @view)
    @user_can_delete = @view && current_user && current_user.has_any_role?(:admin, :librarian)
    @user_can_view_comments = current_user && current_user.has_any_role?(:admin, :agency_admin, :agency_user, :contributor, :librarian)

    respond_to do |format|
      format.html # index.html.slim
      format.js   # index.js.erb
    end
  end

  def state 
    respond_to do |format|
      format.js   # index.js.erb
      format.json { render json: session[:state] }
    end
  end

  def update_state 
    session[:state] = params[:state] unless params[:state].blank? 

    respond_to do |format|
      format.js   # index.js.erb
    end
  end

  # GET /sources/1
  # GET /sources/1.json
  def show
    @source = Source.find(params[:id])
    @access_control = (@source.access_controls.find_by(role: nil) || @source.access_controls.find_by(role: 'public') || @source.access_controls.find_by(role: 'agency'))

    if current_user
      if current_user.has_role?(:admin) || 
        @source.librarians.include?(current_user) || 
        @source.contributors.include?(current_user) || 
        (current_user.has_role?(:agency_admin) && (@source.agency == current_user.agency))
        @upload_count = Upload.where(source: @source).size
      end
    end

    add_breadcrumb 'Metadata', @source
  
    respond_to do |format|
      format.html # show.html.slim
      format.json { render json: @source }
      Watch.update_last_seen_at(@source, current_user) if user_signed_in?
    end
  end

  # GET /sources/new
  # GET /sources/new.json
  def new
    @source = Source.new

    if user_signed_in?
      @eligible_contributors = User.where(agency: current_user.agency).with_any_role(:admin, :contributor).reject{|u| u == current_user }.map{ |c| [user_name_or_email(c), c.id] }
      @eligible_librarians = User.where(agency: current_user.agency).with_any_role(:admin, :librarian).reject{|u| u == current_user }.map{ |c| [user_name_or_email(c), c.id] }
      @selected_contributors = [[user_name_or_email(current_user), current_user.id]]
      @selected_librarians = [[user_name_or_email(current_user), current_user.id]]
      @contributors = @eligible_contributors + @selected_contributors
      @librarians = @eligible_librarians + @selected_librarians
      @admin_librarians = {}
      @admin_contributors = {}
      configure_multiselect_data(@admin_librarians, "librarian")
      configure_multiselect_data(@admin_contributors, "contributor")
    end

    respond_to do |format|
      format.html # new.html.slim
      format.json { render json: @source }
    end
  end

  # GET /sources/1/edit
  def edit
    @source = Source.find(params[:id])
    @eligible_contributors = []
    contributors = User.where(agency: @source.agency).with_any_role(:admin, :contributor)
    contributors.each { |c| @eligible_contributors << [user_name_or_email(c), c.id] unless @source.contributors.include?(c) }
    @selected_contributors = @source.contributors.map{|c| [user_name_or_email(c), c.id]}
    @contributors = @eligible_contributors + @selected_contributors
    @admin_contributors = {}
    configure_multiselect_data(@admin_contributors, "contributor")

    @eligible_librarians = []
    librarians = User.where(agency: @source.agency).with_any_role(:admin, :librarian)
    librarians.each { |c| @eligible_librarians << [user_name_or_email(c), c.id] unless @source.librarians.include?(c) }
    @selected_librarians = @source.librarians.map{|c| [user_name_or_email(c), c.id]}    
    @librarians = @eligible_librarians + @selected_librarians
    @admin_librarians = {}  
    configure_multiselect_data(@admin_librarians, "librarian")
      
    

    add_breadcrumb 'Edit Metadata'
  end

  # POST /sources
  # POST /sources.json
  def create
    @source = Source.new(params[:source])
    corrected_source = params[:source]
    @source.contributor_ids = corrected_source[:contributor_ids].reject(&:blank?) if corrected_source[:contributor_ids]
    @source.librarian_ids = corrected_source[:librarian_ids].reject(&:blank?) if corrected_source[:librarian_ids]

    respond_to do |format|
      if @source.save
        @source.contributor_ids.map { |contributor_id| User.find(contributor_id).add_role(:contributor) } if @source.contributor_ids
        @source.librarian_ids.map { |librarian_id| User.find(librarian_id).add_role(:librarian) } if @source.librarian_ids
        @source.contributors.push(current_user) if (current_user && current_user.has_role?(:contributor)) && !@source.contributors.include?(current_user)
        @source.librarians.push(current_user) if (current_user && current_user.has_role?(:librarian)) && !@source.librarians.include?(current_user)
        AccessControl.where(source_id: @source.id, role: "agency", show: true, download: true, comment: true).first_or_create
        Watch.where(user_id: current_user.id, source_id: @source.id, last_seen_at: Time.now).first_or_create if (current_user && current_user.has_role?(:contributor))
        alert_admins_to_contribution(@source)
        format.html { redirect_to @source, notice: 'Source was successfully created.' }
        format.json { render json: @source, status: :created, location: @source }
      else
        format.html { render action: "new" }
        format.json { render json: @source.errors, status: :unprocessable_entity }
        if user_signed_in?
          @eligible_contributors = User.with_any_role(:admin, :contributor).reject{|u| u == current_user }.map{ |c| [c.email, c.id] }
          @eligible_librarians = User.with_any_role(:admin, :librarian).reject{|u| u == current_user }.map{ |c| [c.email, c.id] }
          @selected_contributors = [[current_user.email, current_user.id]]
          @selected_librarians = [[current_user.email, current_user.id]]
        end
      end
    end
  end

  # PUT /sources/1
  # PUT /sources/1.json
  def update
    @source = Source.find(params[:id])
    updated_source = params[:source]
    updated_source[:contributor_ids] = updated_source[:contributor_ids].reject(&:blank?) if updated_source[:contributor_ids]
    updated_source[:librarian_ids] = updated_source[:librarian_ids].reject(&:blank?) if updated_source[:librarian_ids]

    respond_to do |format|
      if @source.update_attributes(updated_source)
        updated_source[:contributor_ids].map { |contributor_id| User.find(contributor_id).add_role(:contributor) } if updated_source[:contributor_ids]
        updated_source[:librarian_ids].map { |librarian_id| User.find(librarian_id).add_role(:librarian) } if updated_source[:librarian_ids]
        format.html { redirect_to @source, notice: 'Source was successfully updated.' }
        format.json { head :no_content }
        Watch.trigger(@source)
      else
        format.html { render action: "edit" }
        format.json { render json: @source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sources/1
  # DELETE /sources/1.json
  def destroy
    @source = Source.find(params[:id])
    @source.destroy

    respond_to do |format|
      format.html { redirect_to sources_url }
      format.json { head :no_content }
    end
  end

  # GET /sources/1/import
  def import
    @source = Source.find(params[:id])
    @view = View.new
  end

  def watch
    @source = Source.find(params[:id])
    if params[:all_views]
      @source.views.each do |view|
        if current_user.watches.find_by(view: view).nil?
          new_watch = Watch.new({user_id: current_user.id, view_id: view.id, last_seen_at: Time.now})
          new_watch.save
        end
      end
      redirect_to (request.env["HTTP_REFERER"] || sources_path), notice: "You are now watching all of #{@source.name}'s views."
    else
      new_watch = Watch.new({user_id: current_user.id, source_id: @source.id, last_seen_at: Time.now})
      redirect_to (request.env["HTTP_REFERER"] || sources_path), notice: "You are now watching #{@source.name}." if new_watch.save
    end
  end

  def unwatch
    @source = Source.find(params[:id])
    if params[:all_views]
      @source.views.each { |view| view.watches.find_by(user: current_user).delete unless view.watches.find_by(user: current_user).nil? }
      redirect_to (request.env["HTTP_REFERER"] || sources_path), notice: "You are no longer watching any of #{@source.name}'s views."
    else
      current_user.watches.find_by(source_id: @source.id).delete
      redirect_to (request.env["HTTP_REFERER"] || sources_path), notice: "You are no longer watching #{@source.name}."
    end
  end

  def switch_catalog_view
    session[:catalog_view] = params[:catalog_view]
    respond_to do |format|
      format.js {render nothing: true }
    end
  end

  def render_catalog_table
    @sources = AccessControl.viewable_sources(current_user)
    @relevant_sources = @sources
  end

  def render_catalog_list
    @sources = AccessControl.viewable_sources(current_user)
    @relevant_sources = @sources
    puts '*'*8
    print params[:source]
    puts '*'*8
    print @relevant_sources
    @contributor = params[:contributor_id] if params[:contributor_id] && !params[:contributor_id].blank?
    @librarian = params[:librarian_id] if params[:librarian_id] && !params[:librarian_id].blank?
  end

  def get_disclaimer
    @source = Source.find(params[:id])
    @disclaimer = @source.try(:disclaimer)
  end

  private

  def get_admins
    if user_signed_in?
      @contributor = params[:contributor] if params[:contributor] && params[:contributor] == "true"
      @librarian = params[:librarian] if params[:librarian] && params[:librarian] == "true"
      @agency_admin = params[:agency_admin] if params[:agency_admin] && params[:agency_admin] == "true"
      @admin = (params[:admin] if params[:admin] && params[:admin] == "true") || current_user.has_role?(:admin)
    end
  end

  def enforce_access_controls
    @source = Source.find(params[:id])
    if user_signed_in?
      redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to view apps from this data source." if !AccessControl.viewable_sources(current_user).include?(@source)
    else
      redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to view apps from this data source." if !AccessControl.viewable_sources(nil).include?(@source)
    end
  end
end
