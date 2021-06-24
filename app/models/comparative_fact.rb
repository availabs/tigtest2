class ComparativeFact < ActiveRecord::Base
  extend AggregateableFact

  belongs_to :view
  belongs_to :area
  belongs_to :statistic
  belongs_to :base_statistic, class_name: 'Statistic'

  def self.pivot?
    false
  end

  def self.exportable_as_shp?
    true
  end

  def self.styleable?
    true
  end

  def self.has_multiple_value_columns?
    true
  end

  def enclosing_area
    area.enclosing_areas.first
  end

  def percent
    base_value == 0.0 ? 0.0 : value / base_value
  end

  def area_number_only
    /\d+\.?\d*/.match(area.name)[0]
  end

  def fips_code
    area.fips_code
  end

  def self.aggregate_query(view, aggregate_level, area_filter = nil)
    join_levels, agg_join_index, filter_join_index = self.get_join_levels(view, aggregate_level, area_filter)

    # The basic query
    base = includes(:area).where(view_id: view)

    if join_levels > 0
      # Add the area joins needed.
      join = :enclosing_areas
      (1..(join_levels-1)).each do |i|
        join = {enclosing_areas: join}
      end
      base = base.joins(area: join)
    else
      base = base.joins(:area)
    end
    
    # Now use arel to inspect the constructed query so that we can get join table aliases
    # to use in subsequent where clauses.

    # the first join is from the fact to areas
    # the next 2n joins are on pairs, area_enclosures and areas
    the_joins = base.arel.join_sources.dup

    # drop the first join, we're not interested in it
    the_joins.shift

    # get the table name or alias associated with each subsequent join that we *are*
    # interested in.
    join_aliases = the_joins.each_slice(2).collect do |j|
      case j[1].left.class.name
      when 'Arel::Table'
        j[1].left.name
      when 'Arel::Nodes::TableAlias'
        j[1].left.right
      end
    end
    agg_join_index -= 1
    filter_join_index -= 1 if area_filter

    # now we know the table aliases, add the condition and grouping
    if agg_join_index >= 0
      base = base.where("#{join_aliases[agg_join_index]}.type = ?", aggregate_level).group("#{join_aliases[agg_join_index]}.name")
    else
      # no grouping at all
    end

    # and same for if we are filtering by area
    if area_filter
      base = base.where("#{join_aliases[filter_join_index]}.id = ?", area_filter.id)
    end

    base
  end

  # Actually aggregate.
  def self.aggregate(view, aggregate_level, area_filter = nil, ignore = nil, agg_function = :sum, filters = {}, ignore1 = nil, aggregate_by = :value)
    join_levels, agg_join_index, filter_join_index = self.get_join_levels(view, aggregate_level, area_filter)
    if agg_join_index > 0
      query = self.aggregate_query(view, aggregate_level, area_filter)
      case agg_function
      when :sum
        query.sum(aggregate_by)
      when :average
        if aggregate_by == :percent
          query.average("value / nullif(base_value, 0)")
        else
          query.average(aggregate_by)
        end
      end
    else # effectively no aggregation
      query = self.apply_area_filter(view, area_filter, nil)
      # Wrap results as if they had been grouped by areas.name
      results = query.pluck('areas.name', aggregate_by).collect { |t| [t[0], t[1]] }
      Rails.logger.debug results
      Hash[results]
    end
  end   
  
  def self.apply_area_filter(view, area, area_types)
    base = includes(:statistic, area: :enclosing_areas).where(view_id: view)
    if area.nil? && area_types.nil?
      base
    elsif area.nil?
      base.where(areas: {type: area_types})
    elsif area.is_study_area? 
      base.joins(area: :base_geometry).where("ST_Intersects(?, base_geometries.geom)", area.base_geometry.try(:geom))
    elsif area_types.nil?
      join_enclosures(base, area)
    else
      area_ids = area.enclosed_areas.pluck(:id)
      area_ids << area.id
      join_enclosures(base.where(areas: {type: area_types}), area_ids)
    end
  end

  def self.get_data(view, area, area_types, lower, upper, value_column)
    rows = range_select(apply_area_filter(view, area, area_types), lower, upper, value_column)
    rows.collect {|row| {
      "area" => row.area.name, 
      "area_type" => row.area.type, 
      "value" => row.value, 
      "percent" => row.percent
    }}
  end
  
  def self.join_enclosures(base, areas)
    base.joins(area: :areas_enclosing).where(area_enclosures: {enclosing_area_id: areas})
  end

  # Select facts where percent is >= lower and <= upper
  # Assumes facts all have same view
  def self.range_select(facts, lower, upper, value_column)
    return facts if !value_column || (lower.blank? && upper.blank?)
    
    is_percent_column = value_column.to_sym == :percent

    if !lower.blank?
      lower = lower.to_i
      if is_percent_column
        facts = facts.where('CAST(value as float)/NULLIF(base_value, 0) >= ?', lower/100.0)
      else
        facts = facts.where("#{value_column} >= ?", lower)
      end
    end

    if !upper.blank?
      upper = upper.to_i
      if is_percent_column
        facts = facts.where('CAST(value as float)/NULLIF(base_value, 0) <= ?', upper/100.0)
      else
        facts = facts.where("#{value_column} <= ?", upper)
      end
    end

    facts
  end

  def self.to_csv(view)
    CSV.generate do |csv|
      csv << [view.title] if view
      csv << view.column_labels
      apply_area_filter(view, nil, nil).each do |fact|
        row = []
        view.columns.each do |col|
          row << fact.send(col)
        end
        csv << row
      end
    end
  end

  def self.statistic_types
    {
      'Population Below Poverty Level': '% Below Poverty Level',
      'Minority Population': '% Minority'
    }
  end

  def self.update_statistic(view, stat_type)
    return unless stat_type.present?

    # Base statistic
    base_stat = Statistic.where(name: 'Base Population').first_or_create

    # specific statistic

    stat = Statistic.where(name: stat_type).first_or_create
    view.statistic = stat
    if stat_type == '% Below Poverty Level'
      view.column_labels = ['County', 'Census Tract', 'FIPS', 'Population', 'Population Below Poverty', 'Percent Below Poverty']
    elsif stat_type == '% Minority'
      view.column_labels = ['County', 'Census Tract', 'FIPS', 'Population', 'Minority Population', 'Percent Minority']
    end

    view.save(validate: false)
  end

  def self.configure_default_columns(view, stat_type)
    return nil unless view.present?
    
    update_statistic(view, stat_type)
    
    # common view attributes    
    view.topic_area = 'Comparative Socio-economics'
    view.data_levels = [Area::AREA_LEVELS[:census_tract]]
    view.columns = ['enclosing_area', 'area_number_only', 'fips_code', 'base_value', 'value', 'percent']
    view.column_types = ['','','','numeric','numeric','percent']
    view.value_columns = ['value', 'percent']
    view.value_name = :value

    view.save(validate: false)
  end

  def self.upload_extensions
    'csv'
  end

  def self.process_upload(io, view, year, month, extension, &block)
    return unless extension == '.csv'

    # Clear existing facts
    yield('deleting') if block_given?
    where(view: view).delete_all
    
    processCSV(io, view, &block)
  end

  def self.processCSV(file_name, view)
    return nil unless view.present? && view.statistic.present?

    base_stat = Statistic.where(name: 'Base Population').first_or_create
    stat = view.statistic

    if stat.name == '% Minority'
      use_field_difference_as_value = true
      base_field = :hc01_vc43
      field = :hc01_vc49
    elsif stat.name == '% Below Poverty Level'
      base_field =  :hc01_est_vc01 
      field =  :hc02_est_vc01
    end
    
    return nil unless base_field.present? && field.present?  
    
    csv_data = CSV.table(file_name) # read csv in table mode
    area_level = :census_tract

    # area identification of each row, parsed to construct census tract
    area_sym = :geography # 'Geography'
    fips_sym = :id2 # 'Id2'
    
    # process each row
    yield('processing', 0) if block_given?
    csv_data.each_with_index do |row, row_index|
      yield('counting', row_index) if block_given? && row_index % 100 == 0
      area = Area.parse(row[area_sym], area_level, row[fips_sym].to_i)

      rec = ComparativeFact.where(view: view,
                                  area: area,
                                  base_statistic: base_stat,
                                  statistic: stat
                                  ).first_or_create
      base_value = row[base_field]
      value = row[field]
      value = base_value - value if use_field_difference_as_value
      rec.update_attributes(base_value: base_value, value: value)
    end

    yield('processed') if block_given?
  end
end
