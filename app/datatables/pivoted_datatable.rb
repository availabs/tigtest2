### TODO FIXME TODO FIXME: MUST to verify that sorting and filtering work.

class PivotedDatatable < AjaxDatatablesRails::Base
  include ToCsv

  def initialize(params, options={})
    @col_count = params[:columns].to_unsafe_h.count
    super
  end

  # This depends on view
  def sortable_columns
    unless @sortable_columns
      # Check first column, which is usually special
      @sortable_columns = case options[:view].columns[0]
      when 'area'
        (options[:area_type] == "taz") ? ["CAST(areas.name AS INT)"] : ['Area.name']
      when 'tmc'
        ['Tmc.name']
      when 'link'
        ['Link.link_id']
      else
        []
      end

      if options[:view].data_model == SpeedFact
        @sortable_columns += ['Road.name', 'Road.number', 'SpeedFact.direction']
      elsif options[:view].data_model == LinkSpeedFact
        @sortable_columns += ['Road.name', 'Road.number', 'Link.direction']
      end

      @sortable_columns += options[:view].columns[@sortable_columns.size..-1]
    end
    @sortable_columns
  end

  def searchable_columns
    unless @searchable_columns
      # Check first column, which is usually special
      @searchable_columns = case options[:view].columns[0]
      when 'area'
        ['Area.name']
      when 'tmc'
        ['Tmc.name']
      when 'link'
        ['Link.link_id']
      else
        []
      end

      if [SpeedFact, LinkSpeedFact].include? options[:view].data_model
        @searchable_columns += ['Road.name', 'Road.number']
      end
    end
    @searchable_columns
  end

  def as_json(opts = {})
    row_name = options[:view].row_name || :area
    count_sym = "#{row_name}_id".to_sym
    {
      :draw => params[:draw].to_i,
      :recordsTotal =>  get_raw_records(true).count(count_sym),
      :recordsFiltered => filter_records(get_raw_records(true)).count(count_sym),
      :data => data
    }
  end

  def col_count
    (@col_count - 1)
  end

  private

  # override base
  def page
    (params[:start].to_i / params[:length].to_i) + 1
  end

  # override base
  def per_page
    params.fetch(:length, 10).to_i * col_count
  end

  # override base
  def filter_records(records)
    records = simple_search(records)
    records = composite_search(records)
    records = range_filter(records)
    records
  end

  # override base
  def sort_records(records)
    sort_by = []
    params[:order].to_unsafe_h.each_value do |item|
      column = sort_column(item)
      dir = sort_direction(item)

      # Check if column represents an integer and assume a value column
      if /\A\d+\z/.match(column)
        index = column.to_i
        view = options[:view]
        model = view.data_model
        column_name = view.column_name || :year
        row_name = view.row_name || :area

        # check if the row_name exists in both the data_model and linked model

        order_name_id = nil
        if row_name.to_s.camelize.constantize.column_names.include? "#{row_name}_id"
          order_name_id = "#{row_name}s.#{row_name}_id".to_sym
        end
        pluck_name_id = "#{model.table_name}.#{row_name}_id".to_sym

        @row_ids = filter_records(get_raw_records)
          .where({column_name => index})
          .group(order_name_id, pluck_name_id)
          .order("avg(#{view.value_name}) #{dir.downcase}")
          .limit(params[:length].to_i)
          .offset(params[:length].to_i*(page - 1))
          .pluck(pluck_name_id)

        sort_by << "nullif(idx(array#{@row_ids.to_s}, #{model.name.tableize}.#{row_name}_id), 0)"
      else
        sort_by << "#{column} #{dir}"
      end

    end

    records.order(sort_by.join(", "))
  end

  # Does not use <model>::range_select as that is too slow
  def range_filter(records)
    lower = params[:lower]
    upper = params[:upper]
    value_name = options[:view].value_name

    if lower.blank? && upper.blank?
      return records
    elsif upper.blank?
      records = records.where("#{value_name} >= ?", lower.to_i)
    elsif lower.blank?
      records = records.where("#{value_name} <= ?", upper.to_i)
    else
      records = records.where("#{value_name} >= ? AND #{value_name} <= ?", lower.to_i, upper.to_i)
    end

    if @row_ids
      # Limit to visible row ids
      row_name = options[:view].row_name || :area
      records = records.where({"#{row_name}_id".to_sym => @row_ids})
    end

    records
  end

  def data
    cols = options[:view].columns
    pivot(options[:view], options[:area], options[:area_type], params[:lower], params[:upper]).map do |fact|
      result = []
      cols.each do |col|
        result << fact[col]
      end
      result
    end
  end

  def get_raw_records(for_count=false)
    area = options[:area]
    area_type = options[:area_type]
    model = options[:model]

    filters = options[:filters].except(options[:view].column_name)
    model.select_facts(options[:view], area, area_type, filters, for_count)
  end

  def join_enclosures(base, areas)
    base.joins(area: :areas_enclosing).where(area_enclosures: {enclosing_area_id: areas})
  end

  def pivot(view, area=nil, area_type=nil, lower=nil, upper=nil)
    column_name = view.column_name || :year
    grid = GatewayGrid.new(sort: false) do |g|
      g.source_data = records
      g.column_name = column_name
      g.row_name = view.row_name || :area
      g.value_name = view.value_name
    end

    grid.build

    rows = Array.new

    is_speed_fact = view.data_model == SpeedFact
    is_link_speed_fact =  view.data_model == LinkSpeedFact

    grid.rows.each do |grid_row|
      row = Hash.new
      index = 0
      # Assume 0th view column is row header
      # But the grid may have gaps compared to the view if certain columns
      # are empty in the selected facts
      row[view.columns[index]] = (grid_row.header.is_a? String) ? grid_row.header : grid_row.header.name
      index += 1

      grid_row.data.each do |fact|
        unless fact.nil?
          # customized info for SpeedFact and LinkSpeedFact
          if is_speed_fact || is_link_speed_fact
            road = fact.road
            if road
              row['road_name'] = road.name
              row['road_number'] = road.number if road.number != '0' # exclude 0
            end
            if is_speed_fact
              row['direction'] = fact.direction
            else
              row['direction'] = fact.link.try(:direction)
            end
          end

          key = fact.send(column_name).to_s
          row[key] = fact.send(view.value_name)
        end
        index +=1
      end
      rows << row
    end
    rows
  end

  def range_count(facts, lower, upper)
    if lower.blank? && upper.blank?
      facts.count
    elsif upper.blank?
      lower = lower.to_i
      facts.where('value >= ?', lower).count
    elsif lower.blank?
      upper = upper.to_i
      facts.where('value <= ?', upper).count
    else
      lower = lower.to_i
      upper = upper.to_i
      facts.where('value >= ? AND value <= ?', lower, upper).count
    end
  end

  def range_select(facts, lower, upper)
    return facts if lower.blank? && upper.blank?

    value_method = facts[0].view.value_name

    if upper.blank?
      lower = lower.to_i
      facts.select { |fact| fact.send(value_method) >= lower }
    elsif lower.blank?
      upper = upper.to_i
      facts.select { |fact| fact.send(value_method) < upper }
    else
      lower = lower.to_i
      upper = upper.to_i
      facts.select do |fact|
        val = fact.send(value_method)
        (val >= lower) && (val < upper)
      end
    end
  end

  def load_paginator
  end

  def paginate_records(records)
    Rails.logger.debug "row_ids: #{@row_ids}"
    if @row_ids
      records.limit(per_page)
    else
      records.offset(offset).limit(per_page)
    end
  end

  # ========== start: ajax-datatables-rails from 0.3.0 to 1.3.1 upgrade patches ==========
  # NOTE: Upgrading jbox-web/ajax-datatables-rails from 0.3.0 to 1.3.1 caused a lot of issues.
  #       Many methods previously defined on AjaxDatatablesRails::Base were removed.
  #       I added them back in by refering to the 0.3.0 source code:
  #       * https://github.com/jbox-web/ajax-datatables-rails/blob/v0.3.0/lib/ajax-datatables-rails/base.rb

  def simple_search(records)
    return records unless (params[:search].present? && params[:search][:value].present?)
    conditions = build_conditions_for(params[:search][:value])
    records = records.where(conditions) if conditions
    records
  end

  def aggregate_query
    conditions = searchable_columns.each_with_index.map do |column, index|
      value = params[:columns]["#{index}"][:search][:value] if params[:columns]
      search_condition(column, value) unless value.blank?
    end
    conditions.compact.reduce(:and)
  end

  def composite_search(records)
    conditions = aggregate_query
    records = records.where(conditions) if conditions
    records
  end

  def sort_column(item)
    new_sort_column(item)
  rescue
    deprecated_sort_column(item)
  end

  def new_sort_column(item)
    model, column = sortable_columns[sortable_displayed_columns.index(item[:column])].split('.')
    col = [model.constantize.table_name, column].join('.')
  end

  def deprecated_sort_column(item)
    sortable_columns[sortable_displayed_columns.index(item[:column])]
  end

  def sort_direction(item)
    options = %w(desc asc)
    options.include?(item[:dir]) ? item[:dir].upcase : 'ASC'
  end

  def sortable_displayed_columns
    @sortable_displayed_columns ||= generate_sortable_displayed_columns
  end

  def generate_sortable_displayed_columns
    @sortable_displayed_columns = []
    params[:columns].to_unsafe_h.each_value do |column|
      @sortable_displayed_columns << column[:data] if column[:orderable] == 'true'
    end
    @sortable_displayed_columns
  end

  def offset
    params.fetch(:start, 0).to_i
  end


  # ========== end: ajax-datatables-rails from 0.3.0 to 1.3.1 upgrade patches ==========

  # ==== Insert 'presenter'-like methods below if necessary
end
