class LinkSpeedFact < Partitioned::MultiLevel
  extend AggregateableFact

  require 'gateway_monkey_patch_postgres.rb'
  require 'gateway_reader.rb'
  require 'zip'
  
  belongs_to :view
  belongs_to :link
  belongs_to :road
  belongs_to :area
  belongs_to :base_geometry

  enum day_of_week: [ :unknown, :sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :weekdays, :weekends, :month ]

  partitioned do |partition|
    partition.using_classes ByYear, ByMonth
    partition.index :hour
    partition.index :day_of_week
    partition.index :road_id
    partition.index :area_id
    partition.index :view_id
    partition.index :link_id
  end

  # aggregated hours
  HOUR_AM = -1
  HOUR_MD = -2
  HOUR_PM = -3
  HOUR_NT = -4
  HOUR_PERIODS = {
    HOUR_AM => (6..9).to_a, 
    HOUR_MD => (10..15).to_a, 
    HOUR_PM => (16..19).to_a, 
    HOUR_NT => (0..5).to_a + (20..23).to_a
  }
  MID_HOURS_PER_PERIOD = {
    HOUR_AM => 8, 
    HOUR_MD => 13, 
    HOUR_PM => 18, 
    HOUR_NT => 1
  }

  def self.pivot?
    true
  end

  def self.exportable_as_shp?
    true
  end

  def self.styleable?
    true
  end

  def self.facts_have_month?
    true
  end
  
  def self.dynamic_columns
    @dynamic_columns ||= ['link', 'road_name', 'road_number', 'direction'] + (0..23).collect {|h| h.to_s}
  end
  
  def self.dynamic_column_labels
    @dynamic_column_labels ||= ['LINK', 'Roadway Name', 'Roadway Number', 'Direction'] + (1..24).collect {|h| format('%02d:00', h.to_i-1) }
  end

  def self.dynamic_column_types
    @dynamic_column_types ||= ['', '', '', ''] + ['numeric']*(dynamic_columns.count - 1)
  end

  def self.partition_tables
    tmp = connection.schema_search_path
    connection.schema_search_path = "link_speed_facts_partitions"
    tables = connection.tables
    connection.schema_search_path = tmp
    tables
  end
  
  # minimum and maximum are now much slower with partitioning
  # derive this from the partitions created
  def self.derive_min_max
    @min_year = 3000
    @max_year = 1999
    @min_months = {}
    @max_months = {}
    
    partition_tables.each do |p|
      year, month = p.sub('p', '').split('_')
      # Skip base table and empty partitions
      next unless month
      month = month.to_i
      next if from_partition(year.to_i, month.to_i).limit(1).empty?
      year = year.to_i
      @min_year = year if year < @min_year
      @max_year = year if year > @max_year

      @min_months[year] ||= month
      @max_months[year] ||= month
      
      @min_months[year] =  month if month < @min_months[year]
      @max_months[year] =  month if month > @max_months[year]
    end
  end
  
  def self.min_year
    derive_min_max unless @min_year
    @min_year
  end
  def self.max_year
    derive_min_max unless @max_year
    @max_year
  end
  def self.min_months
    derive_min_max unless @min_months
    @min_months
  end
  def self.max_months
    derive_min_max unless @max_months
    @max_months
  end

  COL_IDX = {
    link_id: 0,
    hour: 1,
    sunday: 3,
    monday: 6,
    tuesday: 9,
    wednesday: 12,
    thursday: 15,
    friday: 18,
    saturday: 21,
    weekdays: 24,
    weekends: 27,
    month: 30
  }

  # main method for processing uploaded file
  def self.process_upload(io, view, year, month, extension, &block)
    csv = nil
    
    case extension
    when '.zip'
      Zip::File.open(io).each do |entry|
        csv = CSV.new(entry.get_input_stream)
      end
      yield('expanded', 0) if block_given?
    when '.csv'
      csv = CSV.new(io)
    else
      return
    end

    begin
      count = 0
      yield('counting', 0) if block_given?
      csv.each do |_|
        count += 1
        yield('counting', count) if block_given? && count % 1000 == 0
      end
      yield('count', count) if block_given?
      # yield('processing', 0) if block_given?
      csv.rewind
      processCSV(csv, view, year, month, &block)
    ensure
      csv.close
    end
  end
  
  # optional block for status info allowed
  def self.loadCSV(filename, view, year, month, extension, &block)
    # open csv file and loop over rows
    csv = nil
    
    case extension
    when '.zip'
      Zip::File.open(filename).each do |entry|
        csv = CSV.new(entry.get_input_stream)
      end
    when '.csv'
      csv = CSV.open(filename)
    else
      return
    end

    processCSV(csv, view, year, month, &block)
  end
  
  def self.processCSV(csv, view, year, month)
    # create partition table if necessary
    create_new_partition_tables([year]) unless partition_tables.include? "p#{year}"
    create_new_partition_tables([[year, month]]) unless partition_tables.include? "p#{year}_#{month}"

    yield('deleting')
    # delete existing data
    from_partition(year, month).delete_all
    
    row_count = 0
    index = 0
    fact_rows = Array.new(10000)

    csv.each do |row|
      # to limit ruby memory, accumulate hashes for 1000 rows then create_many
      if index >= 10000
        create_many(fact_rows)
        yield('create_many', row_count) if block_given?
        index = 0
      end
      
      hour = row[COL_IDX[:hour]]
      link_id = row[COL_IDX[:link_id]]
      link = Link.find_by(link_id: link_id)
      unless link
        Rails.logger.warn "link with link_id = #{link_id} not found"
        next
      end
      
      # add hashes for 10 time periods
      day_of_weeks.each do |k, v|
        next if v == 0
        
        fact_rows[index] = {
          link_id: link.id,
          view_id: view.id,
          year: year,
          month: month,
          day_of_week: v,
          hour: hour,
          road_id: link.road_id,
          direction: link.direction,
          area_id: link.area_id,
          base_geometry_id: link.base_geometry_id,
          speed: row[COL_IDX[k.to_sym]].to_i
        }
        index += 1
      end
      row_count += 1
    end
    # finish off any remaining rows
    create_many(fact_rows[0..index])
    yield('create_many', row_count) if block_given?
    yield('processed', row_count) if block_given?
  end

  # TODO: make this more flexible in terms of filters vs. columns selected
  # At the moment this assumes :hours is not part of filters but is selected
  # for the pivot column
  def self.select_facts(view, area, area_type, filters, for_count=false)
    # Support averaging by Day of Week
    day_of_week = filters[:day_of_week].to_s.split
    
    base = from_partition(filters[:year], filters[:month]).where(view_id: view)
    filters = filters.except(:day_of_week) if day_of_week.count > 1
    
    # filters.each {|k, v| filters[k] = v.to_i}
    if area 
      if area.is_county?
        filters[:area_id] = [area.id]
      elsif area.is_study_area?
        base = base.joins(link: :base_geometry)
            .where("ST_Intersects(?, base_geometries.geom)", area.base_geometry.try(:geom))
      else
        filters[:area_id] = area.enclosed_areas
        .where(type: Area::AREA_LEVELS[:county]).pluck(:id)
      end
    end

    # case insensitive searching direction
    dir = filters[:direction] unless filters[:direction].blank?
    filters = filters.except(:direction) 
    if dir
      base = base.where("upper(links.direction) = ?", dir.upcase)
    end

    # Assumes filters contains :year and :month for partitioned data
    base = base.where(filters)
    if day_of_week.count > 1
      if for_count
        base = base.includes(:link).where(day_of_week: day_of_week)
      else
        # return the average speed as an integer
        base = base.joins(:link).preload(:link).where(day_of_week: day_of_week)
          .group({link: :link_id}, :view_id, :hour, *filters.keys)
          .select(:link_id, :hour)
          .select('count(link_speed_facts.id), cast(round(avg(speed)) as integer) as speed')
      end
    else
      base = base.includes(:link, :road)
    end
    base
  end

  def self.get_data(year, month, day_of_week, hour, direction, area, lower=nil, upper=nil, include_geom = false)
    return unless (year && month && hour && day_of_week)

    hours_list = parse_filter_hour(hour)

    query_hash = {
      hour: hours_list, 
      day_of_week: day_of_week.to_i
    }

    base = from_partition(year.to_i, month.to_i).joins(:link).select('links.link_id, link_speed_facts.direction')

    if area
      if area.is_county?
        query_hash[:area_id] = [area.id]
      elsif area.is_study_area?
        base = base.joins(link: :base_geometry)
          .where("ST_Intersects(?, base_geometries.geom)", area.base_geometry.try(:geom))
      else
        query_hash[:area_id] = area.enclosed_areas.where(type: Area::AREA_LEVELS[:county]).pluck(:id)
      end
    end

    base = base.where(query_hash)

    unless direction.blank?
      base = base.where("upper(links.direction) = ?", direction.upcase)
    end

    if hours_list.count > 1
      base = base.group('links.link_id, link_speed_facts.year, link_speed_facts.direction')

      base = base.group("links.base_geometry_id") if include_geom

      base = base.select('cast(round(avg(speed)) as integer) as speed')
    else
      base = base.joins("left join roads on roads.id = link_speed_facts.road_id").select(:speed, "roads.name as road_name", "links.direction as direction")
    end

    base = base.select("links.base_geometry_id") if include_geom
    
    if !lower.blank?
      base = base.where('speed >= ?', lower.to_i)
    end

    if !upper.blank?
      base = base.where('speed <= ?', upper.to_i)
    end

    base

  end

      # Construct an AR query with the needed joins for aggregating by multiple levels of areas
  def self.aggregate_query(view, aggregate_level, filters, area_filter = nil, group_by = :hour)
    join_levels, agg_join_index, filter_join_index = self.get_join_levels(view, aggregate_level, area_filter)

    # The basic query
    # LinkSpeedFacts are already grouped at the county level
    base = from_partition(filters[:year], filters[:month]).includes(:area).where(view_id: view)
    if area_filter
      if area_filter.is_county?
        filters[:area_id] = [area_filter.id]
      elsif area_filter.is_study_area?
        base = base.joins(link: :base_geometry)
            .where("ST_Intersects(?, base_geometries.geom)", area_filter.base_geometry.try(:geom))
      else
        filters[:area_id] = area_filter.enclosed_areas
                     .where(type: Area::AREA_LEVELS[:county]).pluck(:id)
      end
    end
    base = base.where(filters)

    if join_levels > 1
      # region or subregion 
      # Add the area joins needed.
      join = :enclosing_areas
      (1..(join_levels - 2)).each do |i|
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
    agg_join_index -= 2
    filter_join_index -= 2 if area_filter

    # now we know the table aliases, add the condition and grouping
    if agg_join_index >= 0
      base = base.where("#{join_aliases[agg_join_index]}.type = ?", aggregate_level)
             .group(group_by, "#{join_aliases[agg_join_index]}.name")
      # and same for if we are filtering by area
      if area_filter
        base = base.where("#{join_aliases[filter_join_index]}.id = ?", area_filter.id)
      end
    else
      # group by county
      base = base.where("areas.type = ?", aggregate_level)
             .group(group_by, "areas.name")
    end

    base
  end

  # Actually aggregate
  def self.aggregate(view, aggregate_level, area_filter = nil, hour = nil, ignore = nil, filters = {}, group_by = :hour)

    join_levels, agg_join_index, filter_join_index =
                                 self.get_join_levels(view, aggregate_level, area_filter)
    if agg_join_index > 0
      dir = filters[:direction] unless filters[:direction].blank?
      filters = filters.except(:direction)  # exclude it as link_speed_facts doesnt have direction field

      Rails.logger.debug filters
      query = self.aggregate_query(view, aggregate_level, filters, area_filter, group_by)
      Rails.logger.debug query.to_sql

      if dir
        query = query.includes(:link).where("upper(links.direction) = ?", dir.upcase)
      end

      query = query.where(hour: hour) if hour
      # Because speed is an integer, average returns a big decimal, so change all the
      # values to floats
      query.average(:speed).each_with_object({}) {|(k, v), h| h[k] = v.to_f}
    end
  end

  def self.parse_filter_hour(hour)
    return [] if !hour 

    hour = hour.to_i

    if hour < 0
      HOUR_PERIODS[hour]
    else
      [hour]
    end
  end

end
