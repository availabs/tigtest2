class SpeedFact < Partitioned::MultiLevel
  extend AggregateableFact

  require 'gateway_monkey_patch_postgres.rb'
  require 'gateway_reader.rb'
  require 'zip'

  belongs_to :view
  belongs_to :tmc
  belongs_to :road
  belongs_to :area
  belongs_to :base_geometry

  validates :tmc, presence: true
  validates :year, numericality: { only_integer: true, greater_than: 1999, less_than: 3000 }
  validates :month, numericality: { only_integer: true, greater_than: 0, less_than: 13 }
  validates :hour, numericality: { only_integer: true, greater_than: 0, less_than: 25 }
  
  enum day_of_week: [ :unknown, :sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday ]
  enum vehicle_class: [ :all_vehicles, :passenger, :freight ]

  partitioned do |partition|
    partition.using_classes ByYear, ByMonth
    partition.index :hour
    partition.index :day_of_week
    partition.index :road_id
    partition.index :area_id
    partition.index :view_id
    partition.index :tmc_id
    partition.index :vehicle_class
  end

  # aggregated hours
  HOUR_AM = -1
  HOUR_MD = -2
  HOUR_PM = -3
  HOUR_NT = -4
  HOUR_PERIODS = {
    HOUR_AM => (7..10).to_a, 
    HOUR_MD => (11..16).to_a, 
    HOUR_PM => (17..20).to_a, 
    HOUR_NT => (1..6).to_a + (21..24).to_a
  }
  MID_HOURS_PER_PERIOD = {
    HOUR_AM => 9, 
    HOUR_MD => 14, 
    HOUR_PM => 19, 
    HOUR_NT => 2
  }

  # Directions
  DIRECTIONS = [
    ["All", ""], 
    ['Eastbound', 'E'],
    ['Westbound', 'W'],
    ['Northbound', 'N'],
    ['Southbound', 'S']
  ]

  def self.exportable_as_shp?
    true
  end

  def self.styleable?
    true
  end

  # minimum and maximum are now much slower with partitioning
  # derive this from the partitions created
  def self.derive_min_max
    @min_year = 3000
    @max_year = 1999
    @min_months = {}
    @max_months = {}
    
    tmp = connection.schema_search_path
    connection.schema_search_path = "speed_facts_partitions"
    tables = connection.tables
    connection.schema_search_path = tmp

    tables.each do |p|
      year, month = p.sub('p', '').split('_')
      # Skip base table and empty partitions
      next unless month
      month = month.to_i

      #puts "#{year}-#{month}"
      #puts "Year exist" if partition_tables.include? "p#{year}"
      #puts "Year Month exist" if partition_tables.include? "p#{year}_#{month}"
      #puts "Empty" if from_partition(year.to_i, month.to_i).limit(1).empty?
      #puts "#{year}-#{month}"
      #puts ""

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
    derive_min_max #unless @min_year
    @min_year
  end
  def self.max_year
    derive_min_max #unless @max_year
    @max_year
  end
  def self.min_months
    derive_min_max #unless @min_months
    @min_months
  end
  def self.max_months
    derive_min_max #unless @max_months
    @max_months
  end
  
  def self.pivot?
    true
  end

  def self.facts_have_month?
    true
  end

  def self.dynamic_columns
    @dynamic_columns ||= ['tmc', 'road_name', 'road_number', 'direction'] + (1..24).collect {|h| h.to_s}
  end
  
  def self.dynamic_column_labels
    @dynamic_column_labels ||= ['TMC', 'Roadway Name', 'Roadway Number', 'Direction'] + (1..24).collect {|h| format('%02d:00', h.to_i-1) }
  end

  def self.dynamic_column_types
    @dynamic_column_types ||= ['', '', '', ''] + ['numeric']*(dynamic_columns.count - 4)
  end

  def self.get_data(year, month, day_of_week, hour, vehicle_class, direction, area, lower=nil, upper=nil, include_geom = false)
    if !(year && month && hour && day_of_week && vehicle_class)
      nil
    else
      days_list = day_of_week.to_s.split
      hours_list = parse_filter_hour(hour)
      
      base = from_partition(year.to_i, month.to_i).joins(:tmc).select("tmcs.name as tmc_id")

      query_hash = {
        hour: hours_list, 
        day_of_week: days_list,
        vehicle_class: vehicle_class.to_i
      }

      if area
        if area.is_county?
          query_hash[:area_id] = [area.id]
        elsif area.is_study_area?
          base = base.joins(tmc: :base_geometry)
            .where("ST_Intersects(?, base_geometries.geom)", area.base_geometry.try(:geom))
        else
          query_hash[:area_id] = area.enclosed_areas.where(type: Area::AREA_LEVELS[:county]).pluck(:id)
        end
      end

      base = base.where(query_hash)

      unless direction.blank?
        base = base.where("upper(speed_facts.direction) = ?", direction.upcase)
      end
      
      if days_list.count > 1 || hours_list.count > 1
        base = base.group('tmcs.name, speed_facts.year, direction')

        base = base.group("tmcs.base_geometry_id") if include_geom

        base = base.select('cast(round(avg(speed)) as integer) as speed, direction')
      else
        base = base.joins("left join roads on roads.id = speed_facts.road_id").select(:speed, "roads.name as road_name", "speed_facts.direction")
      end

      base = base.select("tmcs.base_geometry_id") if include_geom
      
      if !lower.blank?
        base = base.where('speed >= ?', lower.to_i)
      end

      if !upper.blank?
        base = base.where('speed <= ?', upper.to_i)
      end

      base

    end
  end

    # Construct an AR query with the needed joins for aggregating by multiple levels of areas
  def self.aggregate_query(view, aggregate_level, filters, area_filter = nil, group_by = :hour)
    join_levels, agg_join_index, filter_join_index = self.get_join_levels(view, aggregate_level, area_filter)

    # The basic query
    # SpeedFacts are already grouped at the county level
    base = from_partition(filters[:year], filters[:month]).includes(:area).where(view_id: view)
    if area_filter
      if area_filter.is_county?
        filters[:area_id] = [area_filter.id]
      elsif area_filter.type.try(:sym) == :study_area
        base = base.joins(tmc: :base_geometry)
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
    day_of_week = filters[:day_of_week].to_s.split
    filters = filters.except(:day_of_week) if day_of_week.count > 1

    join_levels, agg_join_index, filter_join_index =
                                 self.get_join_levels(view, aggregate_level, area_filter)
    if agg_join_index > 0
      Rails.logger.debug filters

      # case insensitive searching direction
      dir = filters[:direction] unless filters[:direction].blank?
      filters = filters.except(:direction)

      query = self.aggregate_query(view, aggregate_level, filters, area_filter, group_by)
      Rails.logger.debug query.to_sql
      if dir
        query = query.where("upper(speed_facts.direction) = ?", dir.upcase)
      end
      query = query.where(hour: hour) if hour
      query = query.where(day_of_week: day_of_week) if day_of_week.count > 1
      # Because speed is an integer, average returns a big decimal, so change all the
      # values to floats
      query.average(:speed).each_with_object({}) {|(k, v), h| h[k] = v.to_f}
    end
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
        base = base.joins(tmc: :base_geometry)
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
      base = base.where("upper(speed_facts.direction) = ?", dir.upcase)
    end

    # Assumes filters contains :year and :month for partitioned data
    base = base.where(filters)

    if day_of_week.count > 1
      if for_count
        base = base.includes(:tmc).where(day_of_week: day_of_week)
      else
        # Because year appears in both SpeedFact and Tmc, must be fully qualified
        # include count(id) in select to force sql to ignore it
        # return the average speed as an integer

        base = base
          .joins(:tmc)
          .preload(:tmc)
          .joins("left join roads on roads.id = speed_facts.road_id")
          .where(day_of_week: day_of_week)
          .group(:tmc_id, "tmcs.name", :view_id, :hour, *filters.except(:year).keys)
          .group("speed_facts.year, tmcs.index", "speed_facts.direction")
          .group( :road_id, "roads.name", "roads.number")
          .select(:tmc_id, :hour, :road_id, "speed_facts.direction")
          .select('count(speed_facts.id), cast(round(avg(speed)) as integer) as speed')
      end
    else
      base = base.includes(:tmc, :road)
    end

    base
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

  def self.partition_tables
    tmp = connection.schema_search_path
    connection.schema_search_path = "speed_facts_partitions"
    tables = connection.tables
    connection.schema_search_path = tmp
    tables
  end

  def self.process_upload(io, view, year, month, extension, &block)
    csv = nil
    
    case extension
    when '.zip'
      Zip::File.open(io).each do |entry|
        csv = CSV.new(entry.get_input_stream, headers: true, return_headers: false,
                converters: :numeric, header_converters: :symbol)
      end
      yield('expanded', 0) if block_given?
    when '.csv'
      csv = CSV.new(io, headers: true, return_headers: false,
                converters: :numeric, header_converters: :symbol)
    else
      return
    end

    # create partition table if necessary
    create_new_partition_tables([year]) unless partition_tables.include? "p#{year}"
    create_new_partition_tables([[year, month]]) unless partition_tables.include? "p#{year}_#{month}"
    
    # delete all previous data
    from_partition(year, month).where(view: view).delete_all

    yield("Seeding month #{month}")
    processCSV(csv, io, view, year, month, &block)
    #yield('processed #{month} #{year}') if block_given?
    yield('processed') if block_given?
  end

  def self.processCSV(csv, io, view, year, month, &block)
    # internal hash in memory, avoid multiple DB query on same record
    areas = {}
    roads = {}
    tmcs = {}

Delayed::Worker.logger.debug("<speed_fact.processCSV> START")

    tmc_year = SpeedFactTmcVersionMapping.find_by(data_year: year).try(:tmc_year)

    seeds_config = {
      column_names: {
        day_of_week: 'dWeekday',
        direction: 'rdDirection'
      },
      ref_column_names: {
        tmc: 'tmc',
        area: 'County',
        road_name: 'rdName',
        road_number: 'rdNumber',
      },
      value_column_configs: {
        hour_prefix: 'HR',
        vc_affix: {
          all_vehicles: '_allVeh',
          passenger: '_passVeh',
          freight: '_freight'
        }
      }
    }

    county_level = Area::AREA_LEVELS[:county]
    day_col_name = seeds_config[:column_names][:day_of_week].downcase.to_sym
    direction_col_name = seeds_config[:column_names][:direction].downcase.to_sym
    tmc_col_name = seeds_config[:ref_column_names][:tmc].downcase.to_sym
    area_col_name = seeds_config[:ref_column_names][:area].downcase.to_sym
    road_name_col_name = seeds_config[:ref_column_names][:road_name].downcase.to_sym
    road_number_col_name = seeds_config[:ref_column_names][:road_number].downcase.to_sym
    
    hour_prefix = seeds_config[:value_column_configs][:hour_prefix]
    vc_affix_hash = seeds_config[:value_column_configs][:vc_affix]

    # precompute column names
    col_names_vc_values = []

    (1..24).each do |hour|
      col_names = []
      vc_affix_hash.each do |vc, affix|
        vc_value = vehicle_classes[vc]
        col_name = (hour_prefix + hour.to_s + affix).downcase.to_sym
        col_names[vc_value] = col_name
      end
      col_names_vc_values[hour] = col_names
    end

    begin
      yield('count', "#{csv.to_io.size / (1024*1024)} MB") if block_given?

      count = 0

      csv.each do |row|
        puts "PROCESSING NEW ROW"
        count = count + 1

Delayed::Worker.logger.debug("PROCESSING ROW: " + count.to_s)

        #  "area_id"
        area_name = row[area_col_name]
        if !area_name.blank?
          area = areas[area_name]
          if !area
            area = Area.where(name: area_name.try(:titleize), type: county_level).first
            areas[area_name] = area if area
          end
        end

        #  "road_id"
        road_name = row[road_name_col_name].to_s.strip
        road_number = row[road_number_col_name].to_s.strip
        direction = row[direction_col_name].to_s.strip[0] # only first char, e.g., Northbound -> N
        road_index = "#{road_name}#{road_number}#{direction}"
        if !road_index.blank?
          road = roads[road_index]
          if !road
            road = Road.where(name: road_name, number: road_number, direction: direction).first_or_create
            roads[road_index] = road
          end
        end

        #  "tmc_id"
        tmc_name = row[tmc_col_name]
        tmc = tmcs[tmc_name]
        if !tmc
          tmc = Tmc.where(name: tmc_name, year: tmc_year).first
          tmcs[tmc_name] = tmc
        end

        #puts "#{tmc}, #{tmc_name}, #{tmc_col_name}, #{tmc_year}"
        #yield("#{tmc}, #{tmc_name}, #{tmc_col_name}, #{tmc_year}", "#{csv.pos / (1024*1024)} MB") if block_given?

        if !tmc # require TMC presense
Delayed::Worker.logger.debug("match TMC not found for: #{tmc_name}, #{tmc_year}")
          puts "match TMC not found for: #{tmc_name}"
          next
        end
        base_geometry_id = tmc.base_geometry_id

        #  "day_of_week"
        day_of_week_str = row[day_col_name] || ''
        day_of_week = day_of_weeks[day_of_week_str.downcase]
        if !day_of_week
Delayed::Worker.logger.debug("invalid day of week: #{day_of_week_str}")
          puts "invalid day of week: #{day_of_week_str}"
          next
        end

        # Create facts for one full CSV file row at a time
        fact_rows = []
        ActiveRecord::Base.transaction do
          (1..24).each do |hour|
            vehicle_classes.values.each do |vc_value|
              speed = row[col_names_vc_values[hour][vc_value]]
              
              if speed == 0 # skip NULL value
Delayed::Worker.logger.debug("NULL VALUE")
                next
              end

              fact_rows << {view_id: view,
                            road_id: road,
                            direction: direction,
                            tmc_id: tmc,
                            year: year,
                            month: month,
                            hour: hour,
                            day_of_week: day_of_week,
                            vehicle_class: vc_value,
                            area_id: area,
                            base_geometry_id: base_geometry_id,
                            speed: speed}

            end
          end

          create_many(fact_rows)
          yield('create_many', "#{csv.pos / (1024*1024)} MB") if block_given?
        end
      end
    rescue => e 
      puts e.message
      puts "Please check if file exists: #{io}"
    end
  end
  
end
