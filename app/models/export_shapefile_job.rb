ExportShapefileJob = Struct.new(:view, :user, :params) do

  @file_path, @export = nil, nil

  def perform
    @export.update_attributes(status: :processing, message: 'The exporting task is running.') if @export

    model = view.data_model

    if model == DemographicFact
      export_demo_facts
    elsif model == BpmSummaryFact
      export_bpm_summary_facts
    elsif model == ComparativeFact
      export_comp_facts
    elsif model == PerformanceMeasuresFact
      export_perf_measures_facts
    elsif model == RtpProject
      export_rtp_projects
    elsif model == TipProject 
      export_tip_projects
    elsif model == CountFact
      @file_path = CountBasedGisFileExporter.new(view.name, params).export_shp
    elsif model == SpeedFact
      @file_path = TmcBasedGisFileExporter.new(view.name, params).export_shp
    elsif model == LinkSpeedFact
      @file_path = LinkBasedGisFileExporter.new(view.name, params).export_shp 
    end
  end

  def export_demo_facts
    area = params[:area]
    lower = params[:lower]
    upper = params[:upper]
    area_type = Area.parse_area_type(view.data_levels[0])

    data = get_demo_fact_data(area, area_type, lower, upper) # filter

    @file_path = AreaBasedGisFileExporter.new(get_area_based_shp_name, data, area_type, view.geometry_base_year).export_shp
  end

  def export_bpm_summary_facts
    area_type = Area.parse_area_type(view.data_levels[0])

    data = []
    BpmSummaryFact.where(view_id: view, orig_dest: 'orig', purpose: 'Work', mode: 'WT').each do |r|
      data << {
        'area' => r.area.name,
        'area_type' => r.area.type,
        'count' => r.count
      }
    end

    @file_path = AreaBasedGisFileExporter.new(get_area_based_shp_name, data, area_type, view.geometry_base_year).export_shp
  end

  def export_comp_facts
    area = params[:area]
    lower = params[:lower]
    upper = params[:upper]
    current_value_column = params[:current_value_column]
    area_type = Area.parse_area_type(view.data_levels[0])

    data = ComparativeFact.get_data(view, area, area_type, lower, upper, current_value_column)

    @file_path = AreaBasedGisFileExporter.new(get_area_based_shp_name, data, area_type, view.geometry_base_year).export_shp
  end

  def export_perf_measures_facts
    area = params[:area]
    current_period = params[:current_period]
    current_class = params[:current_class]
    lower = params[:lower]
    upper = params[:upper]
    current_value_column = params[:current_value_column]
    area_type = Area.parse_area_type(view.data_levels[0])

    data = PerformanceMeasuresFact.get_data(view, area, area_type, current_period, current_class, lower, upper, current_value_column).collect(&:as_json_for_shp)
    @file_path = AreaBasedGisFileExporter.new(get_area_based_shp_name, data, area_type, view.geometry_base_year, :area).export_shp
  end

  def export_rtp_projects
    data = RtpProject.get_data(
      view[:id], 
      params[:current_ptype], 
      params[:current_sponsor], 
      params[:current_plan_portion], 
      params[:current_year], 
      params[:cost_lower], 
      params[:cost_upper], 
      params[:area], 
      params[:rtp_id])
    data = expand_columns(data, [:geography, :plan_portion, :rtp_id, :sponsor, :description, :ptype])
        
    @file_path = ProjectBasedGisFileExporter.new(view.name, data).export_shp
  end

  def export_tip_projects
    data = TipProject.get_data(
      view[:id], 
      params[:current_ptype], 
      params[:current_mpo], 
      params[:current_sponsor], 
      params[:cost_lower], 
      params[:cost_upper], 
      params[:area], 
      params[:tip_id])
    data = expand_columns(data, [:geography, :ptype, :mpo, :county, :sponsor, :cost, :tip_id, :description])
      
    @file_path = ProjectBasedGisFileExporter.new(view.name, data).export_shp
  end

  def get_area_based_shp_name
    area = params[:area]
    lower = params[:lower]
    upper = params[:upper]

    file_name = view.name.underscore
    file_name += area.name if area.present?
    file_name += "_from_#{lower}" if lower.present?
    file_name += "_to_#{upper}" if upper.present?

    file_name
  end

  def get_demo_fact_data(area=nil, area_type=nil, lower=nil, upper=nil)
    column_names = view.data_model.column_names
    if view.data_model
      if view.data_model.pivot?
        view.data_model.pivot(view, area, area_type, lower, upper)
      elsif column_names.include? 'view_id'
        if column_names.include?('area_id') || column_names.include?('county_id')
          view.data_model.apply_area_filter(view, area, area_type)
        else
          view.data_model.get_base_data(view)
        end
      else
        view.data_model.all
      end
    end
  end

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

  def before(job)
    puts 'created'
    @export = ShapefileExport.where(view: view, delayed_job: job, user: user).first_or_create
    @export.update_attributes(status: :created, 
      message: 'The job has been created. It may take a short while waiting to be processed.')
  end

  def enqueue(job)
    puts 'queued'
    @export.update_attributes(status: :queued, 
      message: 'The job has been put in queue. It may take a short while to get the exported file(.zip).') if @export 
  end

  def success(job)
    puts 'success'
    file_data = Base64.encode64(File.open(@file_path, 'rb') {|f| f.read})
    @export.tmp_shapefile = TmpShapefile.create(data: file_data)
    @export.save
    @export.update_attributes(status: :success, file_path: @file_path.split('/').last, message: 'The exporting task is processed successfully.') if @export 
  end

  def error(job, e)
    puts 'error'
    puts e.message
    @export.update_attributes(status: :error, message: e.message) if @export 
  end

  def failure(job)
    puts 'failure'
    puts job.attributes
    @export.update_attributes(status: :failure, message: "The exporting task has failed. Please try again or contact system admin.") if @export
  end

  def max_attempts
    1
  end

  def queue_name
    'export_shp'
  end

end