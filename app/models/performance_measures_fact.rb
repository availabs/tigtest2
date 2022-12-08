class PerformanceMeasuresFact < ActiveRecord::Base
  extend AggregateableFact

  belongs_to :view
  belongs_to :area

  enum period: [ :all_day, :am_peak, :midday, :pm_peak, :night ]
  enum functional_class: [ :total, :highway, :arterial, :local, :ramps, :other ]

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

  def self.upload_extensions
    'xlsx'
  end

  def self.sortable_searchable_columns(view)
    view.columns.collect do |col|
      if col == 'area'
        "Area.name"
      else
        "PerformanceMeasuresFact.#{col}"
      end
    end
  end
  
  def self.get_base_data(view)
    includes(:area).references(:area).where(view: view).merge(Area.order(:name))
  end

  def self.range_select(facts, lower=nil, upper=nil, value_column=nil)
    return facts if !value_column || (lower.blank? && upper.blank?)

    if !lower.blank?
      lower = lower.to_f
      facts = facts.where("#{value_column} >= ?", lower)
    end

    if !upper.blank?
      upper = upper.to_f
      facts = facts.where("#{value_column} <= ?", upper)
    end

    facts
  end
  
  def self.get_data(view, area, area_type, period, functional_class, lower=nil, upper=nil, value_column=nil)
    base = includes(area: :enclosing_areas)
           .where(view_id: view, period: period, functional_class: functional_class)
           .joins(:area).merge(Area.order(:name))

    base = range_select(base, lower, upper, value_column)

    if area.nil? && area_type.nil?
      base
    elsif area.nil?
      base.where(areas: {type: area_type})
    elsif area.is_study_area? 
      base.joins(area: :base_geometry).where("ST_Intersects(?, base_geometries.geom)", area.base_geometry.try(:geom))
    elsif area_type.nil?
      join_enclosures(base, area)
    elsif area.type == area_type
      base.where(area_id: area.id)
    else
      area_ids = area.enclosed_areas.pluck(:id)
      area_ids << area.id
      join_enclosures(base.where(areas: {type: area_type}), area_ids)
    end
  end

  def self.to_csv(view, rows = nil, extra_columns = [])
    CSV.generate do |csv|
      csv << [view.title] if view
      columns = view.columns + extra_columns
      csv << columns.collect {|c| c.titleize}
      data = rows || get_base_data(view)
      data.each do |fact|
        row = []
        columns.each do |col|
          row << fact.send(col)
        end
        csv << row
      end
    end
  end

  def as_json
    {
      area: area.try(:name),
      area_type: area.try(:type),
      avg_speed: avg_speed.try(:round, 2),
      vehicle_miles_traveled: vehicle_miles_traveled,
      vehicle_hours_traveled: vehicle_hours_traveled,
      functional_class: functional_class,
      period: period
    }
  end

  # shorter column names
  def as_json_for_shp
    {
      area: area.try(:name),
      avg_speed: avg_speed.try(:round, 2),
      vmt: vehicle_miles_traveled,
      vht: vehicle_hours_traveled,
      func_class: functional_class,
      period: period
    }
  end

  def self.join_enclosures(base, areas)
    base.joins(area: :areas_enclosing).where(area_enclosures: {enclosing_area_id: areas})
  end

  # Construct an AR query with the needed joins for aggregating by multiple levels of areas
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
  def self.aggregate(view, aggregate_level, area_filter = nil, ignore = nil, agg_function = :sum, filters = {}, ignore1 = nil, aggregate_by = :vht)
    join_levels, agg_join_index, filter_join_index = self.get_join_levels(view, aggregate_level, area_filter)
    if agg_join_index > 0
      query = self.aggregate_query(view, aggregate_level, area_filter)

      case agg_function
      when :sum
        query.sum(aggregate_by)
      when :average
        query.average(aggregate_by)
      end
    else # effectively no aggregation
      query = self.get_data(view, area_filter, aggregate_level, filters[:period],
                            filters[:functional_class])
      # Wrap results as if they had been grouped by areas.name
      results = query.pluck('areas.name', aggregate_by).collect { |t| [t[0], t[1]] }
      Rails.logger.debug results
      Hash[results]
    end
  end  

  def self.process_upload(io, view, year, month, extension, &block)
    return unless extension == '.xlsx'

    # Clear existing facts
    yield('deleting') if block_given?
    where(view: view).delete_all
    
    # open and process excel file
    xlsx = Roo::Spreadsheet.open(io, extension: :xlsx)
    yield('count', xlsx.last_row) if block_given?

    processXlsx(xlsx, view, &block)
  end

  # input file format
  # three sheets: VMT, VHT, Speed
  # each sheet has format:
  #
  # 1: ["<measure> by County and Functional Class Group"]
  # 2: [nil, nil, "1-Highway", "2-Arterial", "3-Local", "4-Ramps", "5-Other", "Total"]
  # 3: [<county>, <period>, <value>, <value>, .... ]
  # 4: [nil, <period>, <value>, <value>, .... ]
  # 5: [nil, <period>, <value>, <value>, .... ]
  # 6: [nil, <period>, <value>, <value>, .... ]
  # 7: [nil, <period>, <value>, <value>, .... ]
  # 8: [<county>, <period>, <value>, <value>, .... ]
  # ....
  
  def self.processXlsx(xlsx, view, &block)
    county = nil
    # loop over rows
    (1..xlsx.last_row).each do |i|
      facts = {}
      county = process_row(xlsx, view, county, 'VMT', i, facts)
      Delayed::Worker.logger.debug("row #{i} of #{xlsx.last_row}")
    end
    Delayed::Worker.logger.debug("FINISHED")
    #yield('processed', xlsx.last_row) if block_given?
  end
  
  protected

  PERIOD_MAP = {
    'am_peak' => :am_peak,
    'midday' => :midday,
    'pm_peak' => :pm_peak,
    'night' => :night,
    'all_day' => :all_day
  }

  COLUMNS = [:county,:period, :functional_class, :vehicle_miles_traveled, :vehicle_hours_traveled, :avg_speed ]

  FUNCTIONAL_CLASS_MAP = {
    'Interstate / Freeway / Tollway' => :highway,
    'Local Street' => :local,
    'Major Collector' => :arterial,
    'Minor Arterial' => :arterial,
    'Other' => :other,
    'Principal Arterial' => :arterial,
    'Ramp' => :ramps,
    'total' => :total
  }

  def self.process_row(xlsx, view, current_county, sheet, index, facts_by_class)
    row = xlsx.sheet(sheet).row(index)
    # combine COLUMNS and row into a more useful Hash
    puts 'row'
    data = Hash[*COLUMNS.zip(row).flatten]
    fc = FUNCTIONAL_CLASS_MAP[data[:functional_class]]
    Delayed::Worker.logger.debug("row: #{data}")
    

    county = data[:county]
    current_county = county if !county.blank? && (county != current_county)
    return current_county if current_county == 'Total'
    puts current_county
    area = Area.where(name: current_county.try(:titleize), type: 'county').first
    puts "Could not find #{current_county}" unless area
    
    if facts_by_class.empty?
      facts_by_class[fc] = PerformanceMeasuresFact.create(view: view,
                                                          area: area,
                                                          period: PERIOD_MAP[data[:period]],
                                                          functional_class: fc,
                                                          vehicle_miles_traveled: data[:vehicle_miles_traveled],
                                                          vehicle_hours_traveled: data[:vehicle_hours_traveled],
                                                          avg_speed: data[:avg_speed].to_f.round
                                                        )
    
    end

    current_county
  end
  

end
