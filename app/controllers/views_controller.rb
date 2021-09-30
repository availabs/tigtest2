class ViewsController < ApplicationController

  before_action :get_view, only: [:show, :edit, :update, :destroy, :chart, :table, :map, :data_overlay, :export_shp, :demo_statistics, :feature_geometry, :layer_ui, :symbology, :update_year, :tmc_roadname, :link_roadname, :watch, :unwatch]
  before_action :check_valid_view, only: [:chart, :map, :table]
  before_action :set_snapshots, only: [:chart, :map, :table]
  before_filter :enforce_access_controls_show, only: [:chart, :map, :table, :show, :export_shp]
  before_filter :enforce_access_controls_update, only: [:edit]
  before_filter :enforce_ownership, only: [:chart, :map, :table]
  before_action :get_admins, only: [:new, :edit, :create, :update]

  # GET /views/1/map
  def map
    add_view_switch_breadcrumb @view, :map
    add_action_switch_breadcrumb :map

    set_area_variables
    @map_base_config = get_map_base_config
    @map_snapshot_configs = JSON.parse(Snapshot.find(params[:snapshot]).map_settings) if params[:snapshot]

    set_map_filter_variables

    #@slider_value = slider_year.to_i if !slider_year.blank?

    @has_area_dropdown = ![CountFact, UpwpProject, UpwpRelatedContract].include?(@view.data_model)

    @view_config = {
        id: @view.id,
        area_id: session[:area_id],
        year_slider_value: @slider_value,
        base_overlay_path: base_overlay_view_path(@view),
        data_overlay_path: data_overlay_view_path(@view),
        feature_geometry_path: feature_geometry_view_path(@view),
        demo_statistics_path: demo_statistics_view_path(@view),
        tmc_roadname_path: tmc_roadname_view_path(@view),
        link_roadname_path: link_roadname_view_path(@view),
        home_map_view_options: get_home_map_view_options
    }

    respond_to do |format|
      format.html do # map.html.slim
        increment_view_count
        Watch.update_last_seen_at(@view, current_user) if user_signed_in?
      end
    end
  end

  def base_overlay
    overlay_type = params[:overlay_type]
    default_overlay_config = MapLayer.get_layer_config(overlay_type)
    overlay_config = {}
    if default_overlay_config
      overlay_config = default_overlay_config.deep_dup
    end

    render json: overlay_config
  end

  def data_overlay
    set_area_variables(false)
    set_map_filter_variables

    @map_base_config = get_map_base_config

    @view_params = params.merge({:year => @slider_value}).except(:action, :controller, :id)

    map_config = case @view.data_model.try(:name)
    when 'DemographicFact'
      get_map_config_data_for_demo_fact(@slider_value)
    when 'BpmSummaryFact'
      get_map_config_data_for_bpm_summary_fact
    when 'RtpProject'
      get_map_config_data_for_rtp_project
    when 'TipProject'
      get_map_config_data_for_tip_project
    when 'ComparativeFact'
      get_map_config_data_for_comparative_fact
    when 'PerformanceMeasuresFact'
      get_map_config_data_for_performance_measure_fact
    when 'SpeedFact', 'LinkSpeedFact'
      get_map_config_data_for_speed_fact(@view.data_model)
    when 'CountFact'
      get_map_config_data_for_count_fact
    else
      {}
    end

    map_config[:filter_string] = @filter_string

    # print 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'
    # print @filter
    # print 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'

    render json: map_config
  end

  def export_shp
    if !@view.data_model.try(:exportable_as_shp?)
      @message = 'This specific view does not support shapefile export.'
    else
      set_area_variables(false)
      set_map_filter_variables

      job = Delayed::Job.enqueue ExportShapefileJob.new(@view, current_user, get_map_export_params)
      @export = ShapefileExport.where(view: @view, user: current_user, delayed_job: job).first_or_create
      puts 'export queued'
    end

    respond_to do |format|
      format.js
    end
  end

  def demo_statistics
    source_id = @view.source_id
    # given area_id and year, return all available statistics
    render json: DemographicFact.joins(:view, :area, :statistic)
                     .where(
                         areas: {
                             name: params[:area_name],
                             type: params[:area_type]
                         },
                         views: {
                            source_id: source_id,
                          },
                         year: params[:year])
                     .order("statistics.name")
                     .select("statistics.name").distinct
                     .pluck("statistics.name", :value).map { |x| { name: x[0], value: x[1] } }
  end

  def tmc_roadname
    tmc_view = View.find_by_id(params[:view_id])
    if tmc_view
      year = session["year#{tmc_view.id}"]
      month = session["month#{tmc_view.id}"]

      road = SpeedFact.from_partition(year, month)
                 .joins(:tmc).where(tmcs: {name: params[:tmc_name]}).first.try(:road)
    end
    render json: {name: road.try(:display_name)}
  end

  def link_roadname
    link_view = View.find_by_id(params[:view_id])
    if link_view
      year = session["year#{link_view.id}"]
      month = session["month#{link_view.id}"]

      road = LinkSpeedFact.from_partition(year, month).joins(:link).where(links: {link_id: params[:link_id]}).first.try(:road)
    end

    render json: {name: road.try(:display_name)}
  end

  def update_year
    session["slider-#{@view.source.id}-year"] = params[:year].to_i if @view.source && !params[:year].blank?

    render json: {}
  end

  # GET /views/1/table
  def table
    append_search_params if params[:format] == 'csv' && params[:filtered]
    add_view_switch_breadcrumb @view, :table
    add_action_switch_breadcrumb :table

    @search = params[:search]
    @stat = @view.statistic
    @area_type = Area::AREA_LEVELS[:county]
    @area = nil
    @caption = @view.caption
    @snapshot_filters = JSON.parse(Snapshot.find(params[:snapshot]).table_settings) if params[:snapshot]

    set_area_variables

    set_value_column_variable

    if @view.value_name == :density
      @caption = @stat.name if @stat
      @caption += " Density (persons/sq. mile)"
    end

    @use_ajax = false
    if has_ajax?(@view)
      if has_ajax?(@view) && params[:switch] == 'true'
        # puts "--------------------------------------------------------------------------- NON-AJAX LOAD"
        @rows = get_data(@area, @area_type)
      else
        @use_ajax = true
      end
    else
      # puts "--------------------------------------------------------------------------- NON-AJAX LOAD"
      if @view.data_model == PerformanceMeasuresFact
        prepare_perf_measure_filters
        @rows = PerformanceMeasuresFact.get_data(@view, @area, @area_type, @current_period, @current_class, @lower, @upper, @current_value_column)
      else
        @rows = get_data(@area, @area_type)
      end
    end

    # datatables settings
    @lengthMenu = "[[10, 25, 50, 100], [10, 25, 50, 100]]"
    @filterCols = "[]"
    @searchDelay = ([SpeedFact, LinkSpeedFact].include? @view.data_model) ? 1200 : 400
    @default_order = '[[ 0, "asc"]]'
    if (@view.data_model == ComparativeFact) || (@view.data_model == CountFact)
      @default_order = '[[ 2, "asc"]]'
    end
    @count_fact_column_filter = (@view.data_model == CountFact)
    @rtp_project_column_filter = (@view.data_model == RtpProject)
    @tip_project_column_filter = (@view.data_model == TipProject)
    @upwp_project_column_filter = (@view.data_model == UpwpProject)
    @upwp_contract_column_filter = (@view.data_model == UpwpRelatedContract)
    @upwp_pin = params[:upwp_pin] if params[:upwp_pin]
    @upwp_contracts_view = UpwpRelatedContract.first.view if @view.data_model == UpwpProject
    @has_column_filter = @count_fact_column_filter || @rtp_project_column_filter || @tip_project_column_filter || @upwp_project_column_filter || @upwp_contract_column_filter

    @numeric_orderable = true

    @has_area_dropdown = ![CountFact, UpwpProject, UpwpRelatedContract].include?(@view.data_model)
    @has_range_filter = [CountFact, DemographicFact, ComparativeFact, SpeedFact, LinkSpeedFact].include? @view.data_model

    @speed_fact_filters = {}
    possibly_prepare_speed_fact_filters @view.data_model

    set_column_filter_index_defaults
    
    #check for column filter values.  if they exist, save them in the session
    prepare_column_filters 
    set_table_variables
    respond_to do |format|
      format.html {
        increment_view_count
        Watch.update_last_seen_at(@view, current_user) if user_signed_in?

        if @view.data_model == CountFact && @current_year.blank? 
          @current_year = '2013';
        end
      } # table.html.slim

      filename = @view.name.blank? ? "Table" : @view.name.gsub(/[^0-9A-z.\-]/, '_')
      if @view.data_model.pivot? && unswitched?
        # puts "--------------------------------------------------------------------------- AJAX LOAD"
        format.json { render json: PivotedDatatable.new(view_context,
                                                        {
                                                            view: @view,
                                                            model: @view.data_model,
                                                            model_underscored: @view.data_model.to_s.underscore.pluralize,
                                                            area: @area,
                                                            area_type: @area_type,
                                                            filters: @speed_fact_filters,
                                                        })
        }
        format.csv {
          response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.csv"'
          pivoted_table = PivotedDatatable.new(view_context,
                                               {
                                                   view: @view,
                                                   model: @view.data_model,
                                                   model_underscored: @view.data_model.to_s.underscore.pluralize,
                                                   area: @area,
                                                   area_type: @area_type,
                                                   filters: @speed_fact_filters
                                               }) if params[:filtered]
          @view.update_column(:download_count, @view.download_count + 1)
          render text: (params[:filtered] ? pivoted_table.to_csv(@view) : @view.data_model.to_csv(@view))
        }
      elsif @view.data_model == PerformanceMeasuresFact
        format.json { render json: @rows }
        format.csv { 
          response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.csv"'
          @view.update_column(:download_count, @view.download_count + 1)
          extra_cols = ['period', 'functional_class']
          render text: (params[:filtered] ?
                          PerformanceMeasuresFact.to_csv(@view, @rows, extra_cols) :
                          PerformanceMeasuresFact.to_csv(@view, nil, extra_cols))
        }
      else
        # puts "--------------------------------------------------------------------------- AJAX LOAD"
        unpivoted_table = UnpivotedDatatable.new(view_context,
                                                 {
                                                    view: @view,
                                                    model: @view.data_model,
                                                    model_underscored: @view.data_model.to_s.underscore.pluralize,
                                                    area: @area,
                                                    area_types: @area_type,
                                                    value_column: @current_value_column
                                                 })
        format.json { render json: unpivoted_table }
        format.csv {
          response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.csv"'
          @view.update_column(:download_count, @view.download_count + 1)
          render text: (params[:filtered] ? unpivoted_table.to_csv(@view) : @view.data_model.to_csv(@view))
        }
      end
    end
  end

  # GET /views
  # GET /views.json
  def index
    @views = View.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @views }
    end
  end

  # GET /views/1
  # GET /views/1.json
  def show
    @access_control = (@view.access_controls.find_by(role: nil) || @view.access_controls.find_by(role: 'public') || @view.access_controls.find_by(role: 'agency'))
    if current_user
      if current_user.has_role?(:admin) || 
        @view.librarians.include?(current_user) || 
        @view.contributors.include?(current_user) || 
        (current_user.has_role?(:agency_admin) && (@view.source.agency == current_user.agency))
        @upload_count = Upload.where(view: @view).size
      end
    end

    add_view_switch_breadcrumb @view, :view_metadata
    add_breadcrumb 'View Metadata', @view, view: @view
    @view_action = :view_metadata

    respond_to do |format|
      format.html do # show.html.erb
        increment_view_count
        Watch.update_last_seen_at(@view, current_user) if user_signed_in?
      end
      format.json { render json: get_data }
    end
  end

  # GET /views/new
  # GET /views/new.json
  def new
    add_breadcrumb "New View"
    @view = View.new
    @copied_view = View.find(params[:view_id]) if params[:view_id]
    @copy = !params[:view_id].nil?

    if user_signed_in?
      admins = User.with_role(:admin).map { |a| user_array(a) }
      @contributors = User.where(agency: current_user.agency).with_role(:contributor).map { |c| user_array(c) }
      @librarians = User.where(agency: current_user.agency).with_role(:librarian).map { |l| user_array(l) }
      @contributors = (@contributors + admins).uniq
      @librarians = (@librarians + admins).uniq
      @admin_librarians = {}
      @admin_contributors = {}
      configure_multiselect_data(@admin_librarians, "librarian")
      configure_multiselect_data(@admin_contributors, "contributor")
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @view }
    end
  end

  # GET /views/1/edit
  def edit
    admins = User.with_role(:admin)

    @eligible_contributors = []
    contributors = User.where(agency: @view.source.agency).with_role(:contributor)
    contributors.each { |c| @eligible_contributors << user_array(c) unless @view.contributors.include?(c) }
    admins.each { |c| @eligible_contributors << user_array(c) unless @view.contributors.include?(c) }
    @selected_contributors = @view.contributors.map { |c| user_array(c) }
    @contributors = @eligible_contributors + @selected_contributors
    @admin_contributors = {}
    configure_multiselect_data(@admin_contributors, "contributor")

    @eligible_librarians = []
    librarians = User.where(agency: @view.source.agency).with_role(:librarian)
    librarians.each { |c| @eligible_librarians << user_array(c) unless @view.librarians.include?(c) }
    admins.each { |c| @eligible_librarians << user_array(c) unless @view.librarians.include?(c) }
    @selected_librarians = @view.librarians.map { |c| user_array(c) }
    @librarians = @eligible_librarians + @selected_librarians
    @admin_librarians = {}  
    configure_multiselect_data(@admin_librarians, "librarian")

    add_view_switch_breadcrumb @view, :edit_metadata
    add_breadcrumb 'Edit Metadata', @view, view: @view
    @view_action = :edit_metadata
  end

  # POST /views
  # POST /views.json
  def create
    @view = View.new(params[:view])
    corrected_view = params[:view]
    @view.contributor_ids = corrected_view[:contributor_ids].reject(&:blank?) if corrected_view[:contributor_ids]
    @view.librarian_ids = corrected_view[:librarian_ids].reject(&:blank?) if corrected_view[:librarian_ids]
    @view.columns = corrected_view[:columns].map(&:last) if corrected_view[:columns]
    @view.column_labels = corrected_view[:column_labels].map(&:last) if corrected_view[:column_labels]
    @view.column_types = corrected_view[:column_types].map(&:last) if corrected_view[:column_types]
    if corrected_view[:value_columns]
      @view.value_columns = corrected_view[:value_columns].each_with_index.map{ |val_col, idx| @view.columns[idx] if val_col[1] == "true" }.compact
    end
    @view.data_model = corrected_view[:data_model].constantize unless corrected_view[:data_model].blank?
    @view.data_levels = JSON.parse(corrected_view[:data_levels]) if corrected_view[:data_levels]
    @view.data_hierarchy = JSON.parse(corrected_view[:data_hierarchy]) if (corrected_view[:data_hierarchy] && !corrected_view[:data_hierarchy].empty?)

    respond_to do |format|
      if @view.save
        if @view.columns.reject(&:empty?).empty? && @view.data_model.present?
          if @view.data_model == ComparativeFact
            @view.data_model.try(:configure_default_columns, @view, params[:statistic_type])
          else
            @view.data_model.try(:configure_default_columns, @view)
          end
        elsif @view.data_model == ComparativeFact
          @view.data_model.try(:update_statistic, @view, params[:statistic_type])
        end
            
        @view.set_default_symbologies
        @view.add_action(:view_metadata)
        @view.contributor_ids.map { |contributor_id| User.find(contributor_id).add_role(:contributor) } if @view.contributor_ids
        @view.librarian_ids.map { |librarian_id| User.find(librarian_id).add_role(:librarian) } if @view.librarian_ids
        Watch.where(user_id: current_user.id, view_id: @view.id, last_seen_at: Time.now).first_or_create if (current_user && current_user.has_role?(:contributor))
        if @view.source
          if AccessControl.exist_for_object?(@view.source)
            source_access_controls = AccessControl.where(source_id: @view.source.id)
            source_access_controls.each do |access_control|
              clone = access_control.dup
              clone.source_id = nil
              clone.view_id = @view.id
              clone.save
            end
          else
            AccessControl.where(view_id: @view.id, role: "agency", show: true, download: true, comment: true).first_or_create
          end
        end
        alert_admins_to_contribution(@view)
        format.html { redirect_to @view, notice: 'View was successfully created.' }
        format.json { render json: @view, status: :created, location: @view }
      else
        format.html { render action: "new" }
        format.json { render json: @view.errors, status: :unprocessable_entity }
        if user_signed_in?
          @contributors = User.with_any_role(:admin, :contributor).map { |c| user_array(c) }
          @librarians = User.with_any_role(:admin, :librarian).map { |c| user_array(c) }
        end
      end
    end
  end

  # PUT /views/1
  # PUT /views/1.json`
  def update
    updated_view = params[:view]
    updated_view[:contributor_ids] = updated_view[:contributor_ids].reject(&:blank?) if updated_view[:contributor_ids]
    updated_view[:librarian_ids] = updated_view[:librarian_ids].reject(&:blank?) if updated_view[:librarian_ids]
    updated_view[:columns] = updated_view[:columns].map(&:last) if updated_view[:columns]
    updated_view[:column_labels] = updated_view[:column_labels].map(&:last) if updated_view[:column_labels]
    updated_view[:column_types] = updated_view[:column_types].map(&:last) if updated_view[:column_types]
    if updated_view[:value_columns]
      updated_view[:value_columns] = updated_view[:value_columns].each_with_index.map{ |val_col, idx| updated_view[:columns][idx] if val_col[1] == "true" }.compact
    end
    updated_view[:data_model] = updated_view[:data_model].constantize unless updated_view[:data_model].blank?
    updated_view[:data_levels] = JSON.parse(updated_view[:data_levels]) if updated_view[:data_levels]
    updated_view[:data_hierarchy] = JSON.parse(updated_view[:data_hierarchy]) if (updated_view[:data_hierarchy] && !updated_view[:data_hierarchy].empty?)

    respond_to do |format|
      if @view.update_attributes(updated_view)
        if @view.columns.reject(&:empty?).empty? && @view.data_model.present?
          if @view.data_model == ComparativeFact
            @view.data_model.try(:configure_default_columns, @view, params[:statistic_type])
          else
            @view.data_model.try(:configure_default_columns, @view)
          end
        elsif @view.data_model == ComparativeFact && params[:statistic_type].to_s != @view.statistic.try(:name).to_s
          @view.data_model.try(:update_statistic, @view, params[:statistic_type])
        end

        @view.reset_default_symbologies if @view.data_model != updated_view[:data_model]
        flash[:view_id] = @view.id
        updated_view[:contributor_ids].map { |contributor_id| User.find(contributor_id).add_role(:contributor) } if updated_view[:contributor_ids]
        updated_view[:librarian_ids].map { |librarian_id| User.find(librarian_id).add_role(:librarian) } if updated_view[:librarian_ids]
        format.html { redirect_to view_path(@view), notice: 'View was successfully updated.' }
        format.json { head :no_content }
        Watch.trigger(@view)
      else
        format.html { render action: "edit" }
        format.json { render json: @view.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /views/1
  # DELETE /views/1.json
  def destroy
    @view.update_attribute('deleted_at', Time.now)

    respond_to do |format|
      format.html { redirect_to (request.env["HTTP_REFERER"] || root_path), notice: 'View was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def data_recovery
    @views = View.unscoped.where.not(deleted_at: nil)
  end

  def restore
    @view = View.unscoped.find(params[:id])
    @view.update_attribute('deleted_at', nil)

    respond_to do |format|
      format.html { redirect_to (request.env["HTTP_REFERER"] || data_recovery_views_path), notice: 'View was successfully restored.' }
      format.json { head :no_content }
    end
  end

  # return feature geometry envelope
  def feature_geometry
    view_name = params[:view_name]
    key = params[:key]

    if view_name && key
      view = View.where(name: view_name).first
      area_level = view.data_levels[0].to_sym if view && view.data_levels && view.data_levels.size > 0
      if Area::AREA_LEVELS[area_level]
        base = Area.where(name: key, type: area_level)
        base = base.where(year: view.geometry_base_year) if Area.is_versioned?(area_level)
        feat = base.first
      elsif area_level.downcase == :tmc
        feat = Tmc.where(name: key, year: Tmc.data_year_to_geo_year(session["year#{view.id}"] || Tmc.minimum(:year))).first
      elsif area_level.downcase == :link
        feat = Link.where(link_id: key).first
      end

      geom = feat.base_geometry.geom.envelope if feat && feat.base_geometry
    end

    render json: geom
  end

  def layer_ui
    set_map_filter_variables

    respond_to do |format|
      format.js
    end
  end

  def symbology
    @symbology_subject = params[:symbology_subject]
    @color_scheme = params[:color_scheme]

    set_map_filter_variables

    respond_to do |format|
      format.js
    end
  end

  def watch
    new_watch = Watch.new({user_id: current_user.id, view_id: @view.id, last_seen_at: Time.now})
    redirect_to (request.env["HTTP_REFERER"] || sources_path), notice: "You are now watching #{@view.name}." if new_watch.save
  end

  def unwatch
    current_user.watches.find_by(view_id: @view.id).delete
    redirect_to (request.env["HTTP_REFERER"] || sources_path), notice: "You are no longer watching #{@view.name}."
  end

  private

  def get_view
    @view = View.find(params[:id])
  end

  def get_admins
    if user_signed_in?
      @contributor = params[:contributor] if params[:contributor] && params[:contributor] == "true"
      @librarian = params[:librarian] if params[:librarian] && params[:librarian] == "true"
      @agency_admin = params[:agency_admin] if params[:agency_admin] && params[:agency_admin] == "true"
      @admin = (params[:admin] if params[:admin] && params[:admin] == "true") || current_user.has_role?(:admin)
    end
  end

  def slider_year
    year = (params[:year] if !params[:year].blank?) ||
        (session["slider-#{@view.source.id}-year"] if @view.source) ||
        @default_year

    session["slider-#{@view.source.id}-year"] = year if @view.source && !year.blank?

    year
  end

  def slider_time
    time = (params[:time] if !params[:time].blank?) ||
        (session["slider-#{@view.source.id}-time"] if @view.source) ||
        @default_time

    session["slider-#{@view.source.id}-time"] = time if @view.source && !time.blank?

    time
  end

  def set_map_filter_variables
    @include_year_slider = false
    model = @view.data_model
    if model == DemographicFact
      # slider
      @include_year_slider = true
      @slider_min = @view.columns[1].to_i
      col_count = @view.columns.count - 1
      @default_year = @slider_min
      @slider_value = slider_year.to_i if !slider_year.blank?
      @slider_max = @view.columns.last.to_i
      @slider_values = @view.columns[1..@view.columns.size-1].map(&:to_i)
    elsif [SpeedFact, LinkSpeedFact].include? model
      possibly_prepare_speed_fact_filters model
    elsif model == CountFact
      prepare_count_fact_filters
    elsif model == TipProject
      prepare_tip_project_filters
    elsif model == RtpProject
      prepare_rtp_project_filters
    elsif model == PerformanceMeasuresFact
      prepare_perf_measure_filters
    end

    set_value_column_variable

    @lower = session["lower#{@view.id}"]
    @upper = session["upper#{@view.id}"]

    @include_custom_filters = [DemographicFact, ComparativeFact, PerformanceMeasuresFact, SpeedFact, LinkSpeedFact, CountFact].include? @view.data_model
  end

  def set_value_column_variable
    if !params[:value_column].blank?
      @current_value_column = params[:value_column]
      
      # if new param value is not same as previous session value, then indicates it's changed
      # currently only apply for comparative_fact and performance_measures_fact map
      @value_column_changed = @current_value_column != session["value_column#{@view.id}"]
    elsif !session["value_column#{@view.id}"].blank?
      @current_value_column = session["value_column#{@view.id}"]
    else
      @current_value_column = @view.value_columns.try(:first)
    end

    update_sessions({
                       "value_column#{@view.id}" => @current_value_column
                    })
  end

  def set_area_variables update_session_for_area=true
    # lower/upper need to be on per view basis
    update_sessions({
                        "lower#{@view.id}" => params[:lower],
                        "upper#{@view.id}" => params[:upper]
                    })

    if update_session_for_area
      update_sessions({:area_id => params[:area_id]})
    end

    @regions = Area.where(type: Area::AREA_LEVELS[:region]).order(:name)
    @subregions = Area.where(type: Area::AREA_LEVELS[:subregion]).order(:name)
    @study_areas = StudyArea.viewable_by(current_user).sort_by(&:name) #TODO: scope by viewable user

    @caption = @view.caption
    @area = Area.find_by_id(session[:area_id])
    @area_geom_wkt = @area.base_geometry.geom if @area && @area.base_geometry
    @lower = session["lower#{@view.id}"]
    @upper = session["upper#{@view.id}"]

    if @area.nil?
      @area_name = "All"
    elsif @area.is_subregion?
      @area_name = @area.name
      @subregion = @area
    else
      @area_name = @area.name
    end

    # Remove the lowest levels (taz, census_tract) + subregion/region if not all
    reject_list = ['taz', 'census_tract']
    reject_list += ['subregion', 'region'] unless @area.nil?
    @aggregates = @view.data_hierarchy
            .flatten.reject { |d| reject_list.include? d }
            .collect do |d|
          [Area::AREA_LEVEL_DISPLAY[d.to_sym], Area::AREA_LEVELS[d.to_sym]]
        end if !@view.data_hierarchy.blank?
    if @aggregates
      # Check that aggregate_to is in current list
      aggregate_to_key = params[:aggregate_to] ||
          session["aggregate_to#{@view.id}"] ||
          @aggregates.last[1]
      @aggregate_to = @aggregates.select { |a| a[1] == aggregate_to_key }.first || @aggregates.last

      update_sessions({"aggregate_to#{@view.id}" => @aggregate_to[1]})
    else
      @aggregate_to = nil
    end

    view_level = @view.data_levels[0]
    @area_type = Area.parse_area_type(view_level)
    if @area.try(:is_study_area?)
      @current_data_name = 'study area'
    else
      @current_data_name = Area.parse_area_type_name(view_level)
    end
  end

  def get_data(area=nil, area_type=nil, lower=nil, upper=nil)
    column_names = @view.data_model.column_names
    if @view.data_model
      if @view.data_model.pivot?
        @view.data_model.pivot(@view, area, area_type, lower, upper)
      elsif column_names.include? 'view_id'
        if column_names.include?('area_id') || column_names.include?('county_id')
          @view.data_model.apply_area_filter(@view, area, area_type)
        else
          @view.data_model.get_base_data(@view)
        end
      else
        @view.data_model.all
      end
    end
  end

  def get_map_config_data_for_demo_fact(default_year = nil)
    area_type = Area.parse_area_type(@view.data_levels[0])
    if area_type.blank?
      return nil
    end

    {
      include_year_slider: true,
      name: @view.name,
      data: map_data,
      referenceLayerConfig: map_layer_config_by_area_type(area_type),
      showAreaBoundary: get_area_boundary_status,
      referenceColumn: 'area',
      value_column_changed: false,
      symbologies: @view.symbologies.as_json(default_column_name: default_year),
      current_value_column: @current_value_column,
      zoomExtentWKT: zoom_extent_in_wkt,
      is_demo: true
    }
  end

  def get_map_config_data_for_bpm_summary_fact

    @filter_string = "Origin Zones, Work purpose, WT mode"
    area_type = Area::AREA_LEVELS[:taz]
    {
      name: @view.name,
      data: map_data,
      referenceColumn: 'area',
      referenceLayerConfig: map_layer_config_by_area_type(area_type),
      showAreaBoundary: get_area_boundary_status,
      value_column_changed: false,
      current_value_column: @current_value_column,
      symbologies: @view.symbologies.as_json
    }
  end

  def get_map_config_data_for_rtp_project
    prepare_rtp_project_filters
    {
      name: @view.name,
      addRTPWkt: true,
      data: map_data,
      baseUrl: table_view_path(@view),
      zoom_to_rtp_id: @rtp_id,
      zoomExtentWKT: zoom_extent_in_wkt,
      geometry_type: 'MULTIPLE',
      value_column_changed: false,
      current_value_column: @current_value_column,
      symbologies: @view.symbologies.as_json
    }
  end

  def get_map_config_data_for_tip_project
    prepare_tip_project_filters

    if @area && @area.type == 'county'
      @current_county = @area.id
      session["county#{@view.id}"] = @current_county
    end

    {
      name: @view.name,
      addRTPWkt: true,
      data: map_data,
      baseUrl: table_view_path(@view),
      zoom_to_rtp_id: @tip_id,
      zoomExtentWKT: zoom_extent_in_wkt,
      geometry_type: 'MULTIPLE',
      value_column_changed: false,
      current_value_column: @current_value_column,
      symbologies: @view.symbologies.as_json
    }
  end


  def get_map_config_data_for_count_fact

    # null out the filters that exist for the table but not the map
    session["count_variable#{@view.id}"] = nil
    session["in_station#{@view.id}"] = nil
    session["location#{@view.id}"] = nil
    session["sector#{@view.id}"] = nil
    session["route#{@view.id}"] = nil
    session["location#{@view.id}"] = nil
    session["transit_agency#{@view.id}"] = nil

    #now handle the common filters
    year = session["year#{@view.id}"]
    hour = session["hour#{@view.id}"]
    # print "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    # print hour.to_s
    # print 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    current_mode = session["transit_mode#{@view.id}"]
    transit_mode_name = TransitMode.find(current_mode.to_i).name if !current_mode.blank? rescue nil
    current_direction = session["direction#{@view.id}"]

    {
      name: @view.name,
      addCountFactPoint: true,
      data: map_data,
      baseUrl: table_view_path(@view),
      zoomExtentWKT: zoom_extent_in_wkt,
      geometry_type: 'POINT',
      value_column_changed: false,
      current_value_column: @current_value_column,
      symbologies: @view.symbologies.as_json,
      request_data: {
          year: year,
          hour: hour,
          transit_mode: transit_mode_name,
          direction: current_direction
      }
    }
  end

  def get_map_config_data_for_comparative_fact()
    area_type = Area.parse_area_type(@view.data_levels[0])

    {
      name: @view.name,
      data: map_data,
      referenceLayerConfig: map_layer_config_by_area_type(area_type),
      showAreaBoundary: get_area_boundary_status,
      referenceColumn: 'area',
      value_column_changed: @value_column_changed,
      symbologies: @view.symbologies_for_column(@current_value_column).as_json,
      current_value_column: @current_value_column,
      zoomExtentWKT: zoom_extent_in_wkt
    }
  end

  def get_map_config_data_for_performance_measure_fact()
    area_type = Area.parse_area_type(@view.data_levels[0])

    {
      name: @view.name,
      data: map_data,
      referenceLayerConfig: map_layer_config_by_area_type(area_type),
      showAreaBoundary: get_area_boundary_status,
      referenceColumn: 'area',
      value_column_changed: @value_column_changed,
      symbologies: @view.symbologies_for_column(@current_value_column).as_json,
      current_value_column: @current_value_column,
      zoomExtentWKT: zoom_extent_in_wkt
    }
  end

  def get_map_config_data_for_speed_fact(model)
    config = {
        name: @view.name,
        zoomExtentWKT: zoom_extent_in_wkt,
        value_column_changed: false,
        current_value_column: @current_value_column,
        symbologies: @view.symbologies.as_json
    }
    year = session["year#{@view.id}"]

    if model == SpeedFact
      puts "#{year}"
      layer_config = MapLayer.get_layer_config(:tmc, year)
      layer_config["viewId"] = @view.id

      model_config = {
        referenceLayerConfig: layer_config,
        data: map_data,
        referenceColumn: 'tmc_id',
        is_tmc: true
      }
    elsif model == LinkSpeedFact
      layer_config = MapLayer.get_layer_config(:link)
      layer_config["viewId"] = @view.id
      model_config = {
        referenceLayerConfig: layer_config,
        data: map_data,
        referenceColumn: 'link_id',
        is_link: true
      }
    end

    config.merge(model_config || {})
  end

  def get_data_per_area_type(is_pivot, all_data)
    if all_data.length == 0
      []
    end

    first_rec = all_data[0]

    if is_pivot
      if first_rec.has_key? "area_type"
        all_data.group_by { |r| r["area_type"] }
      elsif first_rec.has_key? :area_type
        all_data.group_by { |r| r[:area_type] }
      else
        [all_data]
      end
    else
      if first_rec.respond_to? "area_type"
        all_data.group_by { |r| r["area_type"] }
      elsif first_rec.respond_to? :area_type
        all_data.group_by { |r| r[:area_type] }
      elsif first_rec.respond_to? :area
        all_data.group_by { |r| r.area.type }
      else
        [all_data]
      end
    end
  end

  def area_data_to_geojson(is_hash, data, geom_match_column, area_type)
    data = data || []
    geom_match_column = geom_match_column.to_sym unless is_hash

    data_hash = {}
    area_names = []
    if is_hash
      data.each do |r|
        area_name = r[geom_match_column]
        area_names << area_name

        data_hash[area_name] = r
      end
    else
      data.each do |r|
        area_name = r.area.name
        area_names << area_name

        data_hash[area_name] = r
      end
    end

    base = Area
    base = base.where(year: @view.geometry_base_year) if Area.is_versioned?(area_type)
    areas = base.joins(:base_geometry).select(:name, :base_geometry_id)
    if area_type.blank?
      areas = areas.where(name: area_names)
    else
      areas = areas.where(type: area_type, name: area_names)
    end
  end

  def base_overlay_data_to_geojson(overlay_type)
    BaseOverlay.geojson(overlay_type)
  end


  # Expand and convert to string all row fields corresponding to headers.
  # This is needed mostly for fields that are enumeration types.
  def expand_columns(rows, headers)
    new_rows = []
    rows.each do |row|
      expanded = {}
      headers.each do |header|
        expanded[header] = row.send(header).to_s
      end
      new_rows << expanded
    end
    new_rows
  end

  def add_action_switch_breadcrumb(action)
    @view_action = action
    add_breadcrumb action.to_s.titleize, "/views/#{@view.id}/#{action.to_s}", view: @view
  end

  def add_view_switch_breadcrumb(view, action)
    return unless view

    source = view.source

    add_breadcrumb view.name, "/views/#{@view.id}/#{action.to_s}", view: view, source: source, action: action
  end

  def get_map_base_config
    base_configs = Rails.application.config.map_configs.deep_dup

    # do something to customize map configs
    base_configs[:overlays] = base_configs[:overlays] || []
    if @view.data_model == DemographicFact
      base_configs[:overlays] << {
          :overlay_type => BaseOverlay::OVERLAY_TYPES[:uab]
      }
    elsif @view.data_model == PerformanceMeasuresFact
      base_configs[:overlays] << {
          :overlay_type => BaseOverlay::OVERLAY_TYPES[:bpm_highway]
      }
    elsif @view.data_model == CountFact
      base_configs[:overlays] << {
          :overlay_type => BaseOverlay::OVERLAY_TYPES[:hub_bound]
      }

      base_configs[:map_bounds] = {
          xmin: 40.65,
          ymin: -74.3,
          xmax: 40.87,
          ymax: -73.57
      }

      base_configs[:min_zoom] = 10
    elsif [SpeedFact, LinkSpeedFact].include? @view.data_model
      base_configs[:min_zoom] = 9
    end

    base_configs[:study_area_control_enabled] = current_user.present?

    base_configs
  end

  def prepare_perf_measure_filters
    @periods = PerformanceMeasuresFact.periods.collect {|p, val| 
      if p == 'am_peak'
        label = 'AM Peak'
      elsif p == 'pm_peak'
        label = 'PM Peak'
      else  
        label = p.titleize
      end
      [label, val]
    }
    @classes = PerformanceMeasuresFact.functional_classes.collect {|fc, val| [fc.titleize, val]}

    if !params[:period].blank?
      @current_period = params[:period].to_i
    elsif !session["period#{@view.id}"].blank?
      @current_period = session["period#{@view.id}"].to_i
    else
      @current_period = 0
    end
    if !params[:functional_class].blank?
      @current_class = params[:functional_class].to_i
    elsif !session["functional_class#{@view.id}"].blank?
      @current_class = session["functional_class#{@view.id}"].to_i
    else
      @current_class = 0
    end

    @perf_measure_filters = {
      :period => @current_period,
      :functional_class => @current_class
    }

    @filter_string = @perf_measure_filters.collect do |k, v|
      case k
      when :period
        "Time period: #{PerformanceMeasuresFact.periods.key(v.to_i).titleize}"
      when :functional_class
        "Functional class: #{PerformanceMeasuresFact.functional_classes.key(v.to_i).titleize}"
      end
    end.join(', ')
    
    update_sessions({
                      "period#{@view.id}" => @current_period,
                      "functional_class#{@view.id}" => @current_class
                    })
  end
  
  def possibly_prepare_speed_fact_filters(model, *exceptions)
    return unless [SpeedFact, LinkSpeedFact].include? model
    
    min_year = model.min_year
    max_year = model.max_year
    min_months = model.min_months
    max_months = model.max_months
    @years = (min_months.try(:keys) || []).sort

    @months_table = {}
    @years.each do |y|
      months = []
      (min_months[y]..max_months[y]).each { |m| months << [Date::MONTHNAMES[m], m] }
      @months_table[y] = months
    end

    @days = []
    (1..7).each { |d| @days << [Date::DAYNAMES[d-1], d] }

    @hours = []
    hour_format = '%02d:00'
    if model == SpeedFact
      @days << ['Weekdays', "2 3 4 5 6"]
      @days << ['Weekend', "1 7"]

      (0..23).each { |h| @hours << ["#{format(hour_format, h)} - #{format(hour_format, h+1)}", h+1] }

      # SpeedFact also has vehicle classes
      @vehicle_classes = []
      SpeedFact.vehicle_classes.each { |vc, val| @vehicle_classes << [vc.titleize, val] }
    elsif model == LinkSpeedFact
      # LinkSpeedFact has weekday, weekend, and month as separate enums
      @days << ['Weekdays', 8]
      @days << ['Weekends', 9]
      @days << ['Month', 10]

      (0..23).each { |h| @hours << ["#{format(hour_format, h)} - #{format(hour_format, h+1)}", h] }

      # but no vehicle classes
      exceptions << :vehicle_class
    end

    # only non-aggregated hours are used in hour slider
    @hour_slider_min = @hours[0][1]
    @hour_slider_max = @hours[@hours.size - 1][1]

    # append aggregated hour periods
    @hours << ["AM(06:00-10:00)", -1]
    @hours << ["MD(10:00-16:00)", -2]
    @hours << ["PM(16:00-20:00)", -3]
    @hours << ["NT(20:00-06:00)", -4]

    if !params[:year].blank?
      @current_year = params[:year].to_i
    elsif !session["year#{@view.id}"].blank?
      @current_year = session["year#{@view.id}"].to_i
    else
      @current_year = Date.today.year
      if @current_year < min_year
        @current_year = min_year
      elsif @current_year > max_year
        @current_year = max_year
      end
    end

    if !params[:month].blank?
      @current_month = params[:month].to_i
    elsif !session["month#{@view.id}"].blank?
      @current_month = session["month#{@view.id}"].to_i
    else
      @current_month = Date.today.month

      if min_months[@current_year] && @current_month < min_months[@current_year]
       @current_month = min_months[@current_year]
      elsif max_months[@current_year] && @current_month > max_months[@current_year]
       @current_month = max_months[@current_year]
      end
    end

    @month_options = {}
    @months_table.each do |k, v|
      @month_options[k] = "#{ActionController::Base.helpers.options_for_select(v, @current_month)}"
    end
    @month_options = @month_options.to_json.html_safe

    if !params[:hour].blank?
      @current_hour = params[:hour].to_i
    elsif !session["hour#{@view.id}"].blank?
      @current_hour = session["hour#{@view.id}"]
    else
      @current_hour = Time.new.hour
    end

    if !params[:day_of_week].blank?
      @current_day = params[:day_of_week]
    elsif !session["day_of_week#{@view.id}"].blank?
      @current_day = session["day_of_week#{@view.id}"]
    else
      @current_day = Date.today.wday + 1
    end

    if !params[:vehicle_class].blank?
      @current_vehicle_class = params[:vehicle_class].to_i
    elsif !session["vehicle_class#{@view.id}"].blank?
      @current_vehicle_class = session["vehicle_class#{@view.id}"]
    else
      @current_vehicle_class = 0
    end
    
    if !params[:direction].nil?
      @current_direction = params[:direction]
    elsif !session["direction#{@view.id}"].nil?
      @current_direction = session["direction#{@view.id}"]
    else
      @current_direction = ""
    end

    @speed_fact_filters = {
        :year => @current_year,
        :month => @current_month,
        :hour => @current_hour,
        :day_of_week => @current_day,
        :vehicle_class => @current_vehicle_class,
        :direction => @current_direction
    }.except(*exceptions)

    direction_arrays = model == SpeedFact ? SpeedFact::DIRECTIONS : Link::DIRECTIONS

    @filter_string = @speed_fact_filters.collect do |k, v|

      v_string = v.to_s
      v = v.to_i if k != :direction
      case k
      when :year
        "Year: #{v}"
      when :month
        "Month: #{Date::MONTHNAMES[v]}"
      when :day_of_week
        case v_string.length
          when 1
            "Day of week: #{Date::DAYNAMES[v-1]}"
          when 9 
            "Day of week: Weekdays"
          when 3 
            "Day of week: Weekends"
          else 
            "Day of week: #{Date::DAYNAMES[v-1]}"
        end
      when :vehicle_class
        "Vehicle class: #{SpeedFact.vehicle_classes.key(v).titleize}"
      when :direction
        dir = direction_arrays.select{|x| x[1] == v}.first unless v.blank?
        "Direction: #{dir.first}" if dir
      end
    end.compact.join(', ')
    
    # hour slider related
    @include_hour_slider = true
    @hour_slider_values = (@hour_slider_min..@hour_slider_max).step(1).to_a
    @hour_slider_value = @current_hour
    @hours_hash = Hash[@hours.map {|label, hour| [hour, label]}]

    update_sessions({
                        "year#{@view.id}" => @current_year,
                        "month#{@view.id}" => @current_month,
                        "hour#{@view.id}" => @current_hour,
                        "day_of_week#{@view.id}" => @current_day,
                        "direction#{@view.id}" => @current_direction,
                        "vehicle_class#{@view.id}" => @current_vehicle_class
                    })

  end

  def prepare_count_fact_filters
    @years = []
    min_year = CountFact.minimum(:year)
    max_year = CountFact.maximum(:year)
    (min_year .. max_year).each { |y| @years << [y, y] }

    @hours = []
    @hours << ["12 AM", 0] # This is different from SpeedFact hours
    (1..11).each { |h| @hours << ["#{h} AM", h] }
    @hours << ["12 PM", 12]
    (13..23).each { |h| @hours << ["#{h-12} PM", h] }

    @transit_modes = TransitMode.order(:name).pluck(:name, :id)
    @sectors = Sector.order(:name).pluck(:name, :id)
    
    @transit_directions = [['Inbound', 'Inbound'], ['Outbound', 'Outbound']] # Probably needs refactoring

    if !params[:year].blank?
      @current_year = params[:year].to_i
    elsif !session["year#{@view.id}"].blank?
      @current_year = session["year#{@view.id}"]
    else
      @current_year = Date.today.year
      if @current_year < min_year
        @current_year = min_year
      elsif @current_year > max_year
        @current_year = max_year
      end
    end
    
    if !params[:hour].blank?
      @current_hour = params[:hour].to_i
    elsif !session["hour#{@view.id}"].blank?
      @current_hour = session["hour#{@view.id}"].to_i
    else
      @current_hour = 0
    end

    if !params[:upper_hour].blank?
      @upper_hour = params[:upper_hour].to_i
    elsif !session["upper_hour#{@view.id}"].blank?
      @upper_hour = session["upper_hour#{@view.id}"].to_i
    else
      @upper_hour = 0
    end

    @hour_filter = (@current_hour..@upper_hour).to_a
    if @upper_hour && @current_hour && (@current_hour > @upper_hour)
      #@upper_hour = @current_hour
    end

    if !params[:transit_mode].blank?
      @current_mode = params[:transit_mode].to_i
    elsif !session["transit_mode#{@view.id}"].blank?
      @current_mode = session["transit_mode#{@view.id}"]
      for mode in @transit_modes
        if mode[1] == @current_mode
          @current_mode_string = mode[0]
          break
        end
      end
    end
    
    if !params[:transit_direction].blank?
      @current_direction = params[:transit_direction]
    elsif !session["direction#{@view.id}"].blank?
      @current_direction = session["direction#{@view.id}"]
    end

    if !params[:sector].blank?
      @sector = params[:sector].to_i
    elsif !session["sector#{@view.id}"].blank?
      @sector = session["sector#{@view.id}"]
    end
    @current_sector_string = nil
    if @sector
      for sector in @sectors
        if sector[1] == @sector
          @current_sector_string = sector[0]
          break
        end
      end
    end

    if @view_action == :map 
      @current_mode = TransitMode.find_by(name: 'Vehicles (Auto+Taxi+Trucks+Comm. Vans)').try(:id) if !@current_mode || @current_mode == -1
      @current_mode = @transit_modes[0][1] rescue nil if !@current_mode

      @current_direction = 'Inbound' unless ['Inbound', 'Outbound'].index(@current_direction)
    else
      @current_mode = -1 if !@current_mode
    end

    @count_fact_filters = {
        :year => @current_year,
        :hour => [@current_hour,@upper_hour],
        :transit_mode => @current_mode,
        :transit_direction => @current_direction
    }

    @filter_string = @count_fact_filters.collect do |k, v|
      case k
      when :year
        "Year: #{v}"
      when :hour
        current_hour_label_item = @hours.select {|x| x[1] == @current_hour}
        hour_str = "From: #{current_hour_label_item.first[0]}"

        upper_hour_label_item = @hours.select {|x| x[1] == @upper_hour}
        hour_str += " to " + upper_hour_label_item.first[0]

        hour_str
      when :transit_mode
        v = v.to_i
        "Mode: #{v == -1 ? 'Any' : TransitMode.find_by_id(v).try(:name)}"
      when :transit_direction
        "Direction: #{v ? v.titleize : 'Either'}"
      end
    end.compact.join(', ')
    
    update_sessions({
                        "year#{@view.id}" => @current_year,
                        "hour#{@view.id}" => @current_hour,
                        "upper_hour#{@view.id}" => @upper_hour,
                        "transit_mode#{@view.id}" => @current_mode,
                        "sector#{@view.id}" => @sector,
                        "direction#{@view.id}" => @current_direction
                    })
  end

  def prepare_tip_project_filters

    @tip_ids = TipProject.order(tip_id: :asc).pluck(:tip_id)
    @ptypes = Ptype.where(id: TipProject.select(:ptype_id).uniq).order(:name).pluck(:name, :id)
    @mpos = Mpo.where(id: TipProject.select(:mpo_id).uniq).order(:name).pluck(:name, :id)
    @sponsors = Sponsor.where(id: TipProject.where(view: @view).select(:sponsor_id).uniq.pluck(:sponsor_id)).where.not(name: nil).order(:name).pluck(:name, :id)

    if !(params[:tip_id] == nil)
      @tip_id = params[:tip_id]
    elsif !session["tip_id#{@view.id}"].blank?
      @tip_id = session["tip_id#{@view.id}"]
    end

    if !(params[:ptype] == nil)
      @current_ptype = params[:ptype]
    elsif !session["ptype#{@view.id}"].blank?
      @current_ptype = Ptype.where(name: session["ptype#{@view.id}"]).pluck(:id).first
    end

    if !(params[:mpo] == nil)
      @current_mpo = params[:mpo]
    elsif !session["mpo#{@view.id}"].blank?
      @current_mpo = Mpo.where(name: session["mpo#{@view.id}"]).pluck(:id).first
    end

    if !(params[:county] == nil)
      @current_county = params[:county]
    elsif !session["county#{@view.id}"].blank?
      @current_county = session["county#{@view.id}"]
    end

    if !(params[:sponsor] == nil)
      @current_sponsor = params[:sponsor]
    elsif !session["sponsor#{@view.id}"].blank?
      @current_sponsor = Sponsor.where(name: session["sponsor#{@view.id}"]).pluck(:id).first
    end

    if !(params[:cost_lower] == nil)
      @cost_lower = params[:cost_lower]
    elsif !session["cost_lower#{@view.id}"].blank?
      @cost_lower = session["cost_lower#{@view.id}"]
    end

    if !(params[:cost_upper] == nil)
      @cost_upper = params[:cost_upper]
    elsif !session["cost_upper#{@view.id}"].blank?
      @cost_upper = session["cost_upper#{@view.id}"]
    end
    update_sessions({
                        "ptype#{@view.id}" => @current_ptype.blank? ? "" : Ptype.where(id: @current_ptype).pluck(:name).first,
                        "mpo#{@view.id}" => @current_mpo.blank? ? "" : Mpo.where(id: @current_mpo).pluck(:name).first,
                        "county#{@view.id}" => @current_county,
                        "sponsor#{@view.id}" => @current_sponsor.blank? ? "" : Sponsor.where(id: @current_sponsor).pluck(:name).first,
                        "cost_lower#{@view.id}" => @cost_lower,
                        "cost_upper#{@view.id}" => @cost_upper,
                        "tip_id#{@view.id}" => @tip_id
                    })
  end


  def prepare_rtp_project_filters

    @rtp_ids = RtpProject.order(rtp_id: :asc).pluck(:rtp_id)
    @ptypes = Ptype.where(id: RtpProject.select(:ptype_id).uniq).where.not(name: '').order(:name).pluck(:name, :id)
    @sponsors = Sponsor.where(id: RtpProject.where(view: @view).select(:sponsor_id).uniq.pluck(:sponsor_id)).where.not(name: '').order(:name).pluck(:name, :id)
    @plan_portions = PlanPortion.where(id: RtpProject.where(view: @view).select(:plan_portion_id).uniq).where.not(name: '').order(:name).pluck(:name, :id)
    @years = RtpProject.where.not(year: 0).order(:year).pluck(:year).uniq

    if !(params[:rtp_id] == nil)
      @rtp_id = params[:rtp_id]
    elsif !session["rtp_id#{@view.id}"].blank?
      @rtp_id = session["rtp_id#{@view.id}"]
    end

    if !(params[:ptype] == nil)
      @current_ptype = params[:ptype]
    elsif !session["ptype#{@view.id}"].blank?
      @current_ptype = Ptype.where(name: session["ptype#{@view.id}"]).pluck(:id).first
    end

    if !(params[:sponsor] == nil)
      @current_sponsor = params[:sponsor]
    elsif !session["sponsor#{@view.id}"].blank?
      @current_sponsor = Sponsor.where(name: session["sponsor#{@view.id}"]).pluck(:id).first
    end

    if !(params[:plan_portion] == nil)
      @current_plan_portion = params[:plan_portion]
    elsif !session["plan_portion#{@view.id}"].blank?
      @current_plan_portion = PlanPortion.where(name: session["plan_portion#{@view.id}"]).pluck(:id).first
    end

    if !(params[:current_year] == nil)
      @current_year = params[:current_year]
    elsif !session["year#{@view.id}"].blank?
      @current_year = session["year#{@view.id}"]
    end

    if !(params[:cost_lower] == nil)
      @cost_lower = params[:cost_lower]
    elsif !session["cost_lower#{@view.id}"].blank?
      @cost_lower = session["cost_lower#{@view.id}"]
    end

    if !(params[:cost_upper] == nil)
      @cost_upper = params[:cost_upper]
    elsif !session["cost_upper#{@view.id}"].blank?
      @cost_upper = session["cost_upper#{@view.id}"]
    end


    update_sessions({
                        "ptype#{@view.id}" => @current_ptype.blank? ? "" : Ptype.where(id: @current_ptype).pluck(:name).first,
                        "sponsor#{@view.id}" => @current_sponsor.blank? ? "" : Sponsor.where(id: @current_sponsor).pluck(:name).first,
                        "plan_portion#{@view.id}" => @current_plan_portion.blank? ? "" : PlanPortion.where(id: @current_plan_portion).pluck(:name).first,
                        "year#{@view.id}" => @current_year,
                        "cost_lower#{@view.id}" => @cost_lower,
                        "cost_upper#{@view.id}" => @cost_upper,
                        "rtp_id#{@view.id}" => @rtp_id
                    })
  end

  def has_ajax?(view)
    [ComparativeFact, DemographicFact, SpeedFact, CountFact, TipProject, RtpProject, LinkSpeedFact].include? view.data_model
  end

  def unswitched?
    params[:switch].nil? || params[:switch] == 'false'
  end

  private

  def update_sessions(params = {})
    params.each do |key, val|
      session[key] = val if !val.nil?
    end
  end

  def set_snapshots
    @snapshot = Snapshot.new
    @existing_snapshots = Snapshot.where(user: current_user, view: @view, app: params[:action]) if user_signed_in?
  end

  def increment_view_count
    if params[:id]
      view = View.find(params[:id])
      # Use update_column so that updated_at is not modified.
      view.update_column(:view_count, view.view_count + 1)
    end
  end

  def check_valid_view
    print @view.data_model.try(:name)
    if @view
      if not @view.has_action? params[:action]
        redirect_to (request.env["HTTP_REFERER"] || view_path(@view)),
                    alert: "View: #{@view.name} does not support the #{params[:action].titleize} Action. Please correct the view's metadata."
      elsif @view.data_model.blank? || @view.columns.blank? || @view.columns.length < 1
        redirect_to (request.env["HTTP_REFERER"] || view_path(@view)),
                    alert: "View: #{@view.name}, is not valid for #{params[:action].titleize} Action. Please correct the view's metadata."
      end
    else
      redirect_to sources_path, alert: "View does not exist."
    end
  end

  def get_home_map_view_options
    area_level = @view.data_levels[0].downcase.to_sym if @view && @view.data_levels && @view.data_levels.size > 0

    case area_level
      when :route
        {
            center_x: 40.75,
            center_y: -73.990,
            zoom: 12
        }
      when :project
        {
            center_x: 41.145,
            center_y: -73.286,
            zoom: 9
        }
      else
        {
            center_x: 40.864,
            center_y: -73.993,
            zoom: 9
        }
    end
  end

  def get_area_boundary_status
    if [DemographicFact, BpmSummaryFact, ComparativeFact].index(@view.data_model)
      false
    end
  end


  def enforce_access_controls_show
    @view = View.find(params[:id])
    if user_signed_in?
      if AccessControl.viewable_sources(current_user).include?(@view.source)
        redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to view this app." if !AccessControl.viewable_views(current_user, @view.source).include?(@view)
      else
        redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to view this apps from this data source."
      end
    else
      if AccessControl.viewable_sources(nil).include?(@view.source)
        redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to view this app." if !AccessControl.viewable_views(nil, @view.source).include?(@view)
      else
        redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to view this apps from this data source."
      end
    end
  end

  def enforce_access_controls_update
    @view = View.find(params[:id])
    if user_signed_in?
      if AccessControl.viewable_sources(current_user).include?(@view.source)
        redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to edit this metadata." if !(current_user.has_role?(:admin) || @view.contributors.include?(current_user) || @view.librarians.include?(current_user) || (current_user.has_role?(:agency_admin) && (@view.source.agency == current_user.agency)))
      else
        redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to edit this metadata."
      end
    else
      redirect_to (request.env["HTTP_REFERER"] || sources_path), alert: "You are not permitted to edit metadata."
    end
  end

  def enforce_ownership
    @snapshot = Snapshot.find(params[:snapshot]) if params[:snapshot]
    if user_signed_in?
      if params[:snapshot]
        redirect_to (request.env["HTTP_REFERER"] || '/?expand=snap'), alert: "You are not permitted to view this snapshot." if !(@snapshot.viewers.include?(current_user) || @snapshot.published == true || @snapshot.user == current_user)
      end
    else
      if params[:snapshot]
        redirect_to (request.env["HTTP_REFERER"] || root_path), alert: "You are not permitted to view this snapshot." if !@snapshot.published == true
      end
    end
  end

  def map_layer_config_by_area_type(area_type)
    #only TAZ, Census_tract has multipe geometry versions
    geometry_base_year = @view.geometry_base_year if Area.is_versioned?(area_type)
    MapLayer.get_layer_config(area_type, geometry_base_year)
  end

  # Since these variables are both embeded in the javascript and view dependent
  # it's necessary to set all the index values so the javascript is happy
  def set_column_filter_index_defaults
    # Get columns for one view for each data_model class we need to set defaults for
    # Depends on knowing that AR is using YAML::dump to serialize data_model classes
    [CountFact, RtpProject, TipProject].each do |data_model|
      view = View.where(data_model: YAML::dump(data_model)).first
      update_column_filter_indexes(data_model, view)
    end
  end

  def update_column_filter_indexes(data_model, view)
    return unless view
    name = data_model.name.underscore
    cols = view.columns
    cols.each_with_index {|col, idx| instance_variable_set("@#{name}_#{col}_idx", idx.to_s)}
  end
  
  def prepare_column_filters
    data_model = @view.data_model
    columns = @view.columns

    update_column_filter_indexes(data_model, @view)
    
    return unless params[:columns]

    if data_model == CountFact
      ['in_station', 'direction', 'location', 
       'transit_agency', 'year'].each {|var| set_var_search_in_session(CountFact, var)}

      # Because these are exact match, it's necessary to strip off the '^$' delimiters.
      set_var_search_in_session(CountFact, 'count_variable') {|var| var[1...-1]}
      set_var_search_in_session(CountFact, 'transit_route') {|route| route[1...-1]}

      # For these, need to translate name into id
      set_var_search_in_session(CountFact, 'transit_mode') {|name| TransitMode.where(name: name).pluck(:id).first}
      set_var_search_in_session(CountFact, 'sector') {|name| Sector.where(name: name).pluck(:id).first}

      hour, dummy, upper_hour = params[:columns][@count_fact_hour_idx]["search"]["value"].split("-")
      session["hour#{@view.id}"] = hour
      session["upper_hour#{@view.id}"] = upper_hour
      
      session["lower#{@view.id}"] = params[:lower]
      session["upper#{@view.id}"] = params[:upper]

    elsif data_model == RtpProject
      ['rtp_id', 'description', 'year', 'plan_portion',
       'county', 'ptype'].each {|var| set_var_search_in_session(RtpProject, var)}

       # exact match, strip off the '^$' delimiters.
      set_var_search_in_session(RtpProject, 'sponsor') {|sponsor| sponsor[1...-1]}
      cost_lower, dummy, cost_upper = params[:columns][@rtp_project_estimated_cost_idx]["search"]["value"].split("-")
      session["cost_lower#{@view.id}"] = cost_lower
      session["cost_upper#{@view.id}"] = cost_upper
    elsif data_model == TipProject
      ['tip_id', 'ptype', 'county',
       'description'].each {|var| set_var_search_in_session(TipProject, var)}

      cost_lower, dummy, cost_upper = params[:columns][@tip_project_cost_idx]["search"]["value"].split("-")
      session["cost_lower#{@view.id}"] = cost_lower
      session["cost_upper#{@view.id}"] = cost_upper

      # Because it's an exact match, it's necessary to strip off the '^$' delimiters.
      set_var_search_in_session(TipProject, 'mpo') {|mpo| mpo[1...-1]}
      set_var_search_in_session(TipProject, 'sponsor') {|sponsor| sponsor[1...-1]}
    end
    
  end

  # Most of the time we just set the session variable to the value of the search parameter
  # but this method takes a block so that we can do additional work
  def set_var_search_in_session(model, col)
    idx = instance_variable_get("@#{model.name.underscore}_#{col}_idx")
    return unless idx
    search_param = params[:columns][idx]["search"]["value"]
    if block_given?
      value = yield(search_param)
    else
      value = search_param
    end
    session["#{col}#{@view.id}"] = value
  end
    
  def set_table_variables
    @county = session["county#{@view.id}"]
    @tip_id = session["tip_id#{@view.id}"]
    @rtp_id = session["rtp_id#{@view.id}"]
    @mpo = session["mpo#{@view.id}"]
    @description = session["description#{@view.id}"]
    @cost_lower = session["cost_lower#{@view.id}"]
    @cost_upper = session["cost_upper#{@view.id}"]
    @plan_portion = session["plan_portion#{@view.id}"]
    @sponsor = session["sponsor#{@view.id}"]
    @ptype = session["ptype#{@view.id}"]
    @count_var = session["count_variable#{@view.id}"]
    @route = session["transit_route#{@view.id}"]
    @current_mode_string = TransitMode.where(id: session["transit_mode#{@view.id}"]).pluck(:name).first
    @station = session["in_station#{@view.id}"]
    @current_direction = session["direction#{@view.id}"]
    @hub_location = session["location#{@view.id}"]
    @sector = session["sector#{@view.id}"]
    @current_sector_string = Sector.where(id: @sector).pluck(:name).first
    @current_hour = session["hour#{@view.id}"]
    @upper_hour = session["upper_hour#{@view.id}"]
    if @upper_hour && @current_hour && (@current_hour.to_i > @upper_hour.to_i)
      @upper_hour = @current_hour
    end
    @agency = session["transit_agency#{@view.id}"]
    @current_year = session["year#{@view.id}"]
    @lower = session["lower#{@view.id}"]
    @upper = session["upper#{@view.id}"]
  end

  def zoom_extent_in_wkt
    @area.try(:geom_as_wkt)
  end

  def map_data
    model = @view.data_model

    if model == DemographicFact
      area_type = Area.parse_area_type(@view.data_levels[0])

      data = get_data(@area, area_type, @lower, @upper) # filter
    elsif @view.data_model == BpmSummaryFact
      data = []
      BpmSummaryFact.where(view_id: @view, orig_dest: 'orig', purpose: 'Work', mode: 'WT').each do |r|
        data << {
          'area' => r.area.name,
          'area_type' => r.area.type,
          'count' => r.count
        }
      end
    elsif model == RtpProject
      data = RtpProject.get_data(@view[:id], @current_ptype, @current_sponsor, @current_plan_portion, @current_year, @cost_lower, @cost_upper, @area, @rtp_id)
      data = expand_columns(data, [:geography, :plan_portion, :rtp_id, :sponsor, :description, :estimated_cost, :ptype, :year])
    elsif model == TipProject
      data = TipProject.get_data(@view[:id], @current_ptype, @current_mpo, @current_sponsor, @cost_lower, @cost_upper, @area, @tip_id)
      data = expand_columns(data, [:geography, :ptype, :mpo, :county, :sponsor, :cost, :tip_id, :description])
    elsif model == ComparativeFact
      area_type = Area.parse_area_type(@view.data_levels[0])

      data = ComparativeFact.get_data(@view, @area, area_type, @lower, @upper, @current_value_column)
    elsif model == PerformanceMeasuresFact
      area_type = Area.parse_area_type(@view.data_levels[0])

      data = PerformanceMeasuresFact.get_data(@view, @area, @area_type, @current_period, @current_class, @lower, @upper, @current_value_column).as_json

    elsif [SpeedFact, LinkSpeedFact].include? model
      year = session["year#{@view.id}"]
      month = session["month#{@view.id}"]
      day_of_week = session["day_of_week#{@view.id}"]
      hour = session["hour#{@view.id}"]
      vehicle_class = session["vehicle_class#{@view.id}"]
      direction = session["direction#{@view.id}"]

      if model == SpeedFact
        data = SpeedFact.get_data(
          year, month, day_of_week, hour, vehicle_class, direction, @area, @lower, @upper
        )
      elsif model == LinkSpeedFact
        data = LinkSpeedFact.get_data(
          year, month, day_of_week, hour, direction, @area, @lower, @upper
        )
      end
    elsif model == CountFact
      year = session["year#{@view.id}"]
      current_mode = session["transit_mode#{@view.id}"]
      transit_mode_name = TransitMode.find(current_mode.to_i).name if !current_mode.blank? rescue nil
      current_direction = session["direction#{@view.id}"]


      print '****************************** \n'
      print @count_fact_filters[:hour].try(:first)
      print @count_fact_filters[:hour].try(:last)
      print '****************************** \n'

      hour_filter = process_count_fact_hour_filter(@count_fact_filters[:hour].try(:first), @count_fact_filters[:hour].try(:last))
      data = CountFact.get_data(@view, year, hour_filter, current_mode, current_direction, @area, @lower, @upper)
    end

    data
  end

  def get_map_export_params
    model = @view.data_model

    export_params = {}
    
    if [DemographicFact, BpmSummaryFact].index model
      export_params = {
        area: @area,
        lower: @lower,
        upper: @upper
      }
    elsif model == ComparativeFact
      export_params = {
        area: @area,
        lower: @lower,
        upper: @upper,
        current_value_column: @current_value_column
      }
        
    elsif model == PerformanceMeasuresFact
      export_params = {
        area: @area, 
        current_period: @current_period,
        current_class: @current_class,
        lower: @lower,
        upper: @upper,
        current_value_column: @current_value_column
      }
    elsif model == RtpProject
      export_params = {
        current_ptype: @current_ptype, 
        current_sponsor: @current_sponsor, 
        current_plan_portion: @current_plan_portion, 
        current_year: @current_year, 
        cost_lower: @cost_lower, 
        cost_upper: @cost_upper, 
        area: @area, 
        rtp_id: @rtp_id
      }
    elsif model == TipProject
      export_params = {
        current_ptype: @current_ptype, 
        current_mpo: @current_mpo, 
        current_sponsor: @current_sponsor, 
        cost_lower: @cost_lower, 
        cost_upper: @cost_upper, 
        area: @area, 
        tip_id: @tip_id
      }
    elsif model == CountFact
      export_params = {
        view: @view,
        year: session["year#{@view.id}"],
        hour: @count_fact_filters[:hour],
        current_mode: session["transit_mode#{@view.id}"],
        current_direction: session["direction#{@view.id}"],
        area: @area,
        lower: @lower,
        uppper: @upper
      }
    elsif [SpeedFact, LinkSpeedFact].index model
      export_params = {
        year: session["year#{@view.id}"],
        month: session["month#{@view.id}"],
        day_of_week: session["day_of_week#{@view.id}"],
        hour: session["hour#{@view.id}"],
        direction: session["direction#{@view.id}"],
        area: @area,
        lower: @lower,
        uppper: @upper
      }
      if model == SpeedFact
        export_params[:vehicle_class] = session["vehicle_class#{@view.id}"]
      end
    end
    
    export_params
  end

  # some params were removed from URL in order to reduce the length (IE concern)
  # the removed params should expect to have default value as follows:
  # 1. if no "search" is found, then default value is ""
  # 2. for each column, if no "searchable" is found, then default value is "true"
  # 3. for each column, if no "visible" is found, then default value is "true"
  def append_search_params
    default_search_hash = {"value" => "", "regex" => "false"} 
    params["search"] = default_search_hash if params["search"].blank?
    params["columns"].each do |col_params|
      col_param_data = col_params[1]
      col_param_data["search"] = default_search_hash if col_param_data["search"].blank?
      col_param_data["searchable"] = "true" if col_param_data["searchable"].blank?
      col_param_data["visible"] = "true" if col_param_data["visible"].blank?
    end
  end

  # For Count Fact hour filter, e.g., [1,2], would only return data with hour = 1, without hour = 2
  # this is because, the real meaning of hour in Count Fact is starting hour, it really means From 1 to 2
  def process_count_fact_hour_filter(lower_hour, upper_hour)
    lower_hour = 0 if !lower_hour
    upper_hour = 0 if !upper_hour

    # print '******************************'
    # print lower_hour
    # print upper_hour
    # print '*******************************'
    # Rule 1: return full day if min_hour == max_hour

    @hourfilter = []
    if upper_hour >= lower_hour 
      @hourfilter = (lower_hour..(upper_hour-1)).to_a
    else
     @hourfilter = (lower_hour..23).to_a + (0..upper_hour).to_a
    end 

    return @hourfilter
  end

end
