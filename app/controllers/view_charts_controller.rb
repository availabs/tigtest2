class ViewChartsController < ViewsController

  include GoogleVisualr::ParamHelpers

  # GET /views/1/chart
  def chart
    model = @view.data_model
    is_count_fact_model = model == CountFact

    @filter_string = ''
    
    @aggregation_enabled = true

    legend = nil

    if @aggregation_enabled && !model.respond_to?(:aggregate)
      redirect_to (request.env["HTTP_REFERER"] || view_path(@view)),
                  alert: "The data model: '#{@view.data_model}' for view: '#{@view.name}' does not support the #{params[:action].titleize} Action. Please correct the view's metadata."
      return
    end

    add_view_switch_breadcrumb @view, :chart
    add_action_switch_breadcrumb :chart

    if !is_count_fact_model
      @has_area_dropdown = true 
      @area_aggregation_enabled = true 
    else
      @chart_series = {
        direction: 'Direction', 
        transit_mode: 'Mode', 
        sector: 'Sector'
      }
      prepare_count_fact_filters
      set_chart_series
      set_count_variable
      count_variable_name = CountVariable.find_by_id(@count_var).try(:name)
      set_sector
      set_direction
    end

    set_area_variables if @has_area_dropdown
    # Disallow study areas for now until we figure out how to handle aggregation
    @study_areas = nil
    if @area && @area.type == 'study_area'
      @area = nil
      @area_name = 'All'
    end
    set_agg_functions

    set_chart_types

    @include_year_slider = false
    @speed_fact_filters = {}
    possibly_prepare_speed_fact_filters(@view.data_model, :hour)
    @perf_measure_filters = {}
    
    values = []
    left = '15%'
    @offset = 0

    case @chart_type
    when 'LineChart', 'AreaChart'
      explorer = {}
      if is_count_fact_model
        values = get_count_fact_data.values
        rows = values.size / 24 # 24 hours
      else
        values = model.aggregate(@view, @aggregate_to[1], @area, nil,
                                 @agg_function && @agg_function.downcase.to_sym,
                                 @speed_fact_filters).values
        rows = values.size / @view.columns.count
      end

      # Include a scaling factor based on the log of the max value
      # so as to provide more space for data sets with more extreme ranges
      # handle no data case and nils
      safe_values = values.compact
      diff = (safe_values.size > 1 && safe_values.max > safe_values.min) ? (safe_values.max - safe_values.min) : 1
      height = [rows * 35, Math.log10(diff).modulo(1) * 1500].max + 200
      chart_height = '90%'
      chart_width = '70%'
      vTitle = "#{@agg_function} #{@view.statistic.name}"
      if [SpeedFact, LinkSpeedFact, CountFact].include? model
        hTitle = 'Hour'
      elsif model == DemographicFact
        hTitle = 'Year'
      end

      if is_count_fact_model
        vTitle = "#{@agg_function} #{count_variable_name}"
      end

    when 'BarChart', 'PieChart'
      legend = {position: 'none'} if @chart_type == 'BarChart'
      if model == PerformanceMeasuresFact
        prepare_perf_measure_filters
        set_perf_measure_aggregate_by

        hTitle = "#{@agg_function} #{@measures[@aggregate_by]}"
        explorer = nil
        @include_time_slider = false

        values = model.aggregate(@view, @aggregate_to[1], @area, nil,
                                 @agg_function && @agg_function.downcase.to_sym,
                                 @perf_measure_filters, nil, @aggregate_by).values
      elsif model == ComparativeFact
        set_comp_fact_aggregate_by

        hTitle = "#{@agg_function} #{@measures[@aggregate_by]}"
        explorer = nil
        @include_time_slider = false
        @hide_aggregation = true
        values = model.aggregate(@view, @aggregate_to[1], @area, nil,
                                 @agg_function && @agg_function.downcase.to_sym,
                                 nil, nil, @aggregate_by).values
      elsif is_count_fact_model
        hTitle = "#{@agg_function} #{count_variable_name}"
        explorer = nil
        @include_time_slider = false

        values = get_count_fact_data.values
      else
        hTitle = "#{@agg_function} #{@view.statistic.name}"
        explorer = nil
        @include_time_slider = true
        @slider_formatter = ""
        zero_offset = (model == SpeedFact) ? -1 : 0
        @slider_min = @view.columns[1].to_i + zero_offset
        @default_time = @slider_min
        @slider_value = slider_time.to_i if !slider_time.blank?
        @slider_max = @view.columns.last.to_i + zero_offset

        if [SpeedFact, LinkSpeedFact].include? model
          @slider_values = (@slider_min..@slider_max).step(1).to_a
          @units_label = 'Hour'
          @slider_formatter = "{
            formatter: function(value) {
	      return $.formatNumber(value, {format:'00', locale:'us'}) + ':00';
	    }
          }".html_safe
          @format = '%02d:00'
          @offset = 0
        elsif model == DemographicFact
          @slider_values = @view.columns[1..@view.columns.size-1].map(&:to_i)
          @units_label = 'Year'
        end
        
        @time = slider_time.to_i - zero_offset

        values = model.aggregate(@view, @aggregate_to[1], @area, @time,
                                   @agg_function && @agg_function.downcase.to_sym,
                                   @speed_fact_filters).values

      end
      height = (values.size * 25) + 220
      chart_height = '85%'
      chart_width = '78%'
    else
      height = 600
    end

    @fraction_digits = ((values.size > 0) && (values.compact.max < 1000)) ? 2 : 0
    
    options = {
      height: height,
      legend: legend,
      pointSize: 4,
      chartArea: { height: chart_height, width: chart_width, left: left },
      hAxis: {title: hTitle, textPosition: 'in', baseline: nil},
      vAxis: {title: vTitle},
      explorer: explorer
    }

    if model == ComparativeFact && @aggregate_by == :percent
      @show_percentage = true
      options[:hAxis][:format] ='#,###%' # format as %
    end

    @options = js_parameters(options).html_safe

    respond_to do |format|
      format.html do # chart.html.slim
        increment_view_count
        Watch.update_last_seen_at(@view, current_user) if user_signed_in?
      end
      format.json do
        if model == PerformanceMeasuresFact
          results = model.aggregate(@view, @aggregate_to[1], @area, nil,
                                    @agg_function && @agg_function.downcase.to_sym,
                                    @perf_measure_filters, nil, @aggregate_by)
          presenter = AggregatePresenter.create(model, results, @chart_type, @aggregate_to[1])
        elsif model == ComparativeFact
          results = model.aggregate(@view, @aggregate_to[1], @area, nil,
                                   @agg_function && @agg_function.downcase.to_sym,
                                   nil, nil, @aggregate_by)
          presenter = AggregatePresenter.create(model, results, @chart_type, @aggregate_to[1])
        elsif is_count_fact_model
          results = get_count_fact_data
          presenter = AggregatePresenter.create(model, results, @chart_type, nil, @current_series)
        else
          results = model.aggregate(@view, @aggregate_to[1], @area, @time,
                                    @agg_function && @agg_function.downcase.to_sym,
                                    @speed_fact_filters)
          presenter = AggregatePresenter.create(model, results, @chart_type, @aggregate_to[1])
        end

        render json: presenter.to_json
      end
    end

  end

  private

  def set_chart_types
    update_sessions({"chart_type#{@view.id}" => params[:chart_type]})

    if @view.data_model == PerformanceMeasuresFact
      @chart_types = ['BarChart']
    elsif @view.data_model == ComparativeFact
      @chart_types = ['BarChart', 'PieChart']
    elsif @view.data_model == CountFact
      @chart_types = ['LineChart', 'BarChart']
    elsif @view.data_model == DemographicFact
      @chart_types = ['LineChart', 'AreaChart', 'BarChart', 'PieChart']
    else
      @chart_types = ['LineChart', 'AreaChart', 'BarChart']
    end

    @chart_type = session["chart_type#{@view.id}"]
    # set default chart type
    @chart_type = @chart_types.first unless @chart_types.include?(@chart_type)
  end
  
  def set_agg_functions
    update_sessions({"agg_function#{@view.id}" =>
                     params[:agg_function]})

    @agg_functions =
      if [SpeedFact, LinkSpeedFact].include? @view.data_model
        ['Average']
      elsif @aggregate_to && @view.data_hierarchy.try(:first).try(:first) == @aggregate_to[1]
        []
      else
        ['Average', 'Sum']
      end
    
    @agg_function = session["agg_function#{@view.id}"]
    @agg_function = @agg_functions.last unless @agg_functions.include? @agg_function
  end

  def set_perf_measure_aggregate_by
    @measures = {vehicle_miles_traveled: 'VMT', vehicle_hours_traveled: 'VHT', avg_speed: 'Avg. Speed'}
    update_sessions({"aggregate_by#{@view.id}" => safe_to_sym(params[:aggregate_by])})
    @aggregate_by = session["aggregate_by#{@view.id}"] || :vehicle_hours_traveled
  end

  def set_comp_fact_aggregate_by
    stat_type = @view.statistic.try(:name)
    if stat_type == '% Below Poverty Level'
      @measures = {base_value: 'Population', value: 'Population Below Poverty', percent: 'Percent Below Poverty'}
    elsif stat_type == '% Minority'
      @measures = {base_value: 'Population', value: 'Minority Population', percent: 'Percent Minority'}
    end
      
    update_sessions({"aggregate_by#{@view.id}" => safe_to_sym(params[:aggregate_by])})
    @aggregate_by = session["aggregate_by#{@view.id}"] || :value
  end

  def safe_to_sym val
    val.blank? ? nil : val.to_sym
  end

  def set_chart_series
    if !params[:series].blank?
      @current_series = params[:series]
    elsif !session["series#{@view.id}"].blank?
      @current_series = session["series#{@view.id}"]
    elsif @chart_series
      @current_series = @chart_series.keys.try(:first) 
    end

    @current_series = @current_series.to_sym if @current_series

    update_sessions({
                       "series#{@view.id}" => @current_series
                    })
  end

  def set_count_variable
    if !params[:chart_count_var].blank?
      @count_var = params[:chart_count_var]
    elsif !session["count_variable#{@view.id}"].blank?
      @count_variable = session["count_variable#{@view.id}"]
      @count_var = CountVariable.where(name: @count_variable).pluck(:id).first
    else
      @count_var = CountVariable.order(:name).pluck(:id).first
    end

    @count_variable = CountVariable.where(id: @count_var).pluck(:name).first
    
    update_sessions({
                      "count_variable#{@view.id}" => @count_variable
                    })
  end

  def set_sector
    if params[:sector] == ''
      @sector = nil
      @current_sector_string = nil
      session["sector#{@view.id}"] = nil
    end
    @filter_string += ", Sector: #{@current_sector_string || 'Any'}"
  end

  def set_direction
    if params[:transit_direction] == ''
      session["direction#{@view.id}"] = nil
    end
    @current_direction = session["direction#{@view.id}"]
  end

  def get_count_fact_data
    group_by_hour = @chart_type == 'BarChart' ? false : true
    CountFact.aggregate(@view, @current_year, @count_var.to_s, @current_direction, @sector, @current_mode, @current_series, group_by_hour, @agg_function)
  end
end
