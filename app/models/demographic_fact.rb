class DemographicFact < ActiveRecord::Base
  extend AggregateableFact
  
  belongs_to :view
  belongs_to :area
  belongs_to :statistic
  attr_accessible :value, :year

  # each uploaded file should have following view columns
  # prefix{YEAR} column represents each year's data for a given view
  SOURCE_UPLOAD_TAZ_VIEW_SETS ||= {
    :school_enrollment => {prefix: 'EnrolK12_', desc: ''},
    :total_population => {prefix: 'PopTot', desc: 'Household population plus group quarter population'},
    :total_employment => {prefix: 'EmpTot', desc: 'CTPP based'},
    :household_income => {prefix: 'HHInc', desc: 'Average household income'},
    :household_population => {prefix: 'PopHH', desc: 'Population just in households'},
    :group_quarters_population => {prefix: 'PopGQ', desc: 'Institutional GQ + Homeless GQ + Other GQ population'},
    :group_quarters_institutional_population => {prefix: 'PopGQInst', desc: ''},
    :group_quarters_homeless_population => {prefix: 'PopGQHmls', desc: ''},
    :group_quarters_other_population => {prefix: 'PopGQOth', desc: 'Colleges, universities, military, etc.'},
    :households => {prefix: 'Households', desc: 'Number of households'},
    :household_size => {prefix: 'HHSize', desc: 'Average household size', precision: 2},
    :employed_labor_force => {prefix: 'EmpLF', desc: 'Employed Civilian Labor Force'},
    :retail_employment => {prefix: 'EmpRet', desc: 'CTPP based, NAICS: 44-45'},
    :office_employment => {prefix: 'EmpOff', desc: 'CTPP based, NAICS: 51-56'},
    :earnings => {prefix: 'Earn', desc: 'Earnings per worker'},
    :university_enrollment => {prefix: 'EnrolUniv', desc: ''},
  }

  SOURCE_UPLOAD_COUNTY_VIEW_SETS ||= {
    :total_population => {prefix: 'Total_Pop', desc: 'Total population'},
    :total_employment => {prefix: 'Total_Emp', desc: 'Total employment'},
    :payroll_employment => {prefix: 'Payroll_Emp', desc: 'Payroll employment'},
    :proprietors_employment => {prefix: 'Proprietors_Emp', desc: 'Proprietors employment'},
    :household_population => {prefix: 'HH_Pop', desc: 'Population just in households'},
    :group_quarters_population => {prefix: 'GQ_Pop', desc: 'Group quarter population'},
    :households => {prefix: 'Households', desc: 'Number of households'},
    :household_size => {prefix: 'Avg_HH_Size', desc: 'Average household size', precision: 2},
    :employed_labor_force => {prefix: 'Employed_Labor_Force', desc: 'Employed Civilian Labor Force'},
    :labor_force => {prefix: 'Labor_Force', desc: 'Labor Force'}
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

  # whether can upload the whole source
  def self.source_uploadable?
    true
  end

  def self.upload_extensions
    'csv'
  end

  def self.select_facts(view, area, area_type, filters={}, for_count=false)
    base = includes(:area, :statistic).where(view_id: view)
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

  def self.join_enclosures(base, areas)
    base.joins(area: :areas_enclosing).where(area_enclosures: {enclosing_area_id: areas})
  end
  
  def self.max_value(view, area, area_type=nil)
    select_facts(view, area, area_type).maximum(:value)
  end
  
  def self.grid(view, area, area_type=nil)
    grid = GatewayGrid.new(sort: true) do |g|
      g.source_data = select_facts(view, area, area_type)
      g.column_name = :area
      g.row_name = :year
      g.value_name = view.value_name
    end
    
    grid.build

    grid
  end
  
  def self.pivot(view, area=nil, area_type=nil, lower=nil, upper=nil)
    grid = GatewayGrid.new do |g|
      g.source_data = range_select(select_facts(view, area, area_type), lower, upper)
      g.column_name = :year
      g.row_name = :area
      g.value_name = view.value_name
    end
    
    grid.build

    rows = Array.new

    grid.rows.each do |grid_row|
      row = Hash.new
      index = 0
      # Assume 0th view column is row header
      # But the grid may have gaps compared to the view if certain columns
      # are empty in the selected facts
      row[view.columns[index]] = grid_row.header.name
      index += 1
      row["area_type"] = grid_row.header.type

      grid_row.data.each do |fact|
        row[fact.year.to_s] = fact.send(view.value_name) unless fact.nil?
        index +=1
      end
        
      rows << row
    end
    rows
  end

  # Construct an AR query with the needed joins for aggregating by multiple levels of areas
  def self.aggregate_query(view, aggregate_level, area_filter = nil, group_by = :year)
    join_levels, agg_join_index, filter_join_index = self.get_join_levels(view, aggregate_level, area_filter)

    # The basic query
    base = includes(:area, :statistic).where(view_id: view)

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
      base = base.where("#{join_aliases[agg_join_index]}.type = ?", aggregate_level).group("#{base.table_name}.#{group_by}", "#{join_aliases[agg_join_index]}.name")
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
  def self.aggregate(view, aggregate_level, area_filter = nil, year = nil, agg_function = :sum, ignore = nil, group_by = :year, agg_by = :value)
    join_levels, agg_join_index, filter_join_index = self.get_join_levels(view, aggregate_level, area_filter)
    if agg_join_index > 0
      query = self.aggregate_query(view, aggregate_level, area_filter, group_by)
      query = query.where(year: year) if year
      case agg_function
      when :sum
        query.sum(agg_by)
      when :average
        query.average(agg_by)
      end
    else # effectively no aggregation
      query = self.select_facts(view, area_filter, aggregate_level)
      query = query.where(year: year) if year
      # Wrap results as if they had been grouped by year and areas.name
      Hash[query.pluck("#{query.table_name}.year", 'areas.name', :value).collect { |t| [[t[0], t[1]], t[2]] }]
    end
  end  

  # 
  def self.loadCSV(filename, view, stat, outer_type = nil, inner_type = nil)
    Delayed::Worker.logger.debug('load csv')
    CSV.open(filename, headers: true) do |csv|
      enclosing_area_next = true
      enclosing_area = nil
      area_key = nil
      years = nil
      process_headers = true
      
      csv.each do |row|
        # Could not figure out a way to do this outside the loop
        # Getting the headers requires a shift, but that then causes
        # a row of data to be skipped when going into the loop.
        if process_headers
          area_key = csv.headers[0]
          years = Array.new(csv.headers)
          years.shift

          process_headers = false
        end
        

        name = row[area_key]
        Delayed::Worker.logger.debug('csv row, #{name} #{area_key}')

        if name.nil? || name.empty?
          enclosing_area_next = true
          next 
        end

        area = Area.find_or_create_by( name: name.titleize )

        if enclosing_area_next
          enclosing_area = area
          area.update_attributes(type: outer_type) if area.type.nil?
          enclosing_area_next = false
        else
          area.enclosing_areas << enclosing_area if area.enclosing_areas.empty?
          area.type = inner_type
          area.save!

          years.each do |year|
            fact = DemographicFact.where(view_id: view, 
                                         year: year.to_i, 
                                         area_id: area, 
                                         statistic_id: stat).first_or_create
            
            fact.update_attributes(value: row[year].gsub(/[^\d.]/, '').to_f)
          end
          
          
        end
      end
    end
  end

  # Select facts where applied value_name is >= lower and < upper
  # Assumes facts all have same view
  def self.range_select(facts, lower, upper)
    return facts if lower.blank? && upper.blank?

    value_method = facts[0].view.value_name
    
    if upper.blank?
      lower = lower.to_i
      facts.select { |fact| fact.send(value_method) >= lower }
    elsif lower.blank?
      upper = upper.to_i
      facts.select { |fact| fact.send(value_method) <= upper }
    else
      lower = lower.to_i
      upper = upper.to_i
      facts.select do |fact|
        val = fact.send(value_method)
        (val >= lower) && (val <= upper)
      end
    end
  end

  def self.to_csv(view)
    CSV.generate do |csv|
      csv << [view.title] if view
      csv << (view.column_labels.empty? ? view.columns.collect {|c| c.titleize} : view.column_labels)
      pivot(view).each do |fact|
        row = []
        view.columns.each do |col|
          row << fact[col]
        end
        csv << row
      end
    end
  end    

  def density
    if area.size
      scale = statistic.scale || 0
      (value * (10**scale)) / area.size
    else
      0.0
    end
    
  end

  def self.process_source_upload(io, source, from_year, to_year, geometry_base_year, data_level_text, extension, &block)
    return unless io && source && from_year && to_year && (to_year >= from_year)  && geometry_base_year && data_level_text && extension == '.csv'
    data_level = data_level_text.downcase.to_sym
    geometry_base_year = geometry_base_year.to_i

    yield('preparing processing...', 0) if block_given?
    if data_level == :taz
      prepare_taz_uploading(source, io, from_year, to_year, geometry_base_year, &block)
    elsif data_level == :county
      prepare_county_uploading(source, io, from_year, to_year, geometry_base_year, &block)
    end
  end

  private

  def self.prepare_taz_uploading(source, file_path, from_year, to_year, geometry_base_year, &block)
    Delayed::Worker.logger.debug('prepare_taz_uploading')
    data_level = :taz

    data_hierarchy = [["taz", "county", ["subregion", "region"]]]
        
    view_template = {
          :actions => [:table, :map, :chart, :view_metadata, :edit_metadata],
          :options => {
            geometry_base_year: geometry_base_year,
            data_hierarchy: data_hierarchy,
            data_starts_at: DateTime.new(from_year),
            data_ends_at: DateTime.new(to_year),
            rows_updated_at: DateTime.now,
            data_levels: [Area::AREA_LEVELS[data_level]],
            topic_area: "Demographics",
            columns: ['area'].concat(from_year.step(to_year, 5).map { |year| year.to_s }),
            column_labels: ["TAZ"].concat(from_year.step(to_year, 5).map { |year| year.to_s }),
            column_types: [''].concat(from_year.step(to_year, 5).map { |year| 'numeric' }),
            value_name: :value
      }
    }

    stats = {}
      
    SOURCE_UPLOAD_TAZ_VIEW_SETS.each do |k, v| 
      name = k.to_s.titleize
      mappings = []
      (from_year..to_year).step(5) do |year|
        mappings << {
          :field => v[:prefix] + (year-2000).to_s,
          :year => year
        }
      end
      
      set = {
        :statistic => {
          :name => name
        },
        :view => Hash[view_template],
        :precision => v[:precision]
      }
      set[:view][:name] = "#{from_year}-#{to_year} #{name}"
      set[:view][:description] = v[:desc]
      set[:view][:field_mappings] = mappings
      
      stats[k] = set
    end

    # prepare configs for one source / file
    forecast_config = {
      :file_name => file_path,
      :area_level => Area::AREA_LEVELS[data_level], #optional
      :area_value_column => data_level,
      :statistics => []
    }

    SOURCE_UPLOAD_TAZ_VIEW_SETS.keys.each do |stat_index|
      if !stat_index
        next
      end

      stat_config_data = stats[stat_index.to_s.strip.downcase.to_sym]
      if stat_config_data
        forecast_config[:statistics] << stat_config_data
      end
    end

    load_data_from_taz_csv(source, from_year, to_year, geometry_base_year, forecast_config, &block)
  end

  def self.load_data_from_taz_csv(source, from_year, to_year, geometry_base_year, seeds_config)
    data_level = :taz
    # Delayed::Worker.logger.debug("seeds config , #{seeds_config.to_s}")
    Delayed::Worker.logger.debug("load_data_from_taz_csv #{seeds_config[:area_value_column].downcase.to_s}")
    puts 'Source: ' + source.name

    yield('parsing file (take a while)...', 0) if block_given?
    require 'csv'
    file_name = seeds_config[:file_name]
    stats = seeds_config[:statistics]

    csv_data = CSV.table(file_name) # read csv in table mode
    Delayed::Worker.logger.debug("csv_data #{csv_data.length.to_s} #{csv_data.headers}")

    area_level = seeds_config[:area_level]
    area_row_data = csv_data[seeds_config[:area_value_column].downcase.to_sym] # area identification of each row
    Delayed::Worker.logger.debug("#{seeds_config[:area_value_column].downcase.to_sym}")
    Delayed::Worker.logger.debug("csv_data #{csv_data.length.to_s} new:#{area_row_data} ")
    # pre-load the id of area in database based on area_row_data value
    area_lookup = []
    area_row_data.each do |area_value|
      
      area = Area.where(type: data_level, name: area_value.to_s, year: geometry_base_year).first

      Delayed::Worker.logger.debug("Area: #{area} #{area_value.to_s}")

      if area
        Delayed::Worker.logger.debug("Area: #{area.id}")
        area_lookup << area.id
      else
        area_lookup << nil
      end
    end

    row_size = area_row_data.size
    year_count = (to_year - from_year) / 5 + 1
    yield('count', stats.size * year_count * row_size) if block_given?

    counter = 0
    stats.each_with_index do |obj, index|
      stat_config = obj[:statistic]
      if stat_config
        stat = Statistic.find_or_create_by(name: stat_config[:name])
        stat_config.each do |attr, value|
          stat.update_attribute(attr, value)
        end
        puts 'statistic: ' + stat.name
      end

      view_config = obj[:view]
      if view_config
        counter = index * row_size * year_count
        view_name = view_config[:name]

        yield("creating view #{view_name}", counter) if block_given?

        view = View.where(name: view_name, source: source, statistic: stat).first_or_create
        view.update_attributes(data_model: DemographicFact, description: view_config[:desc])
        
        view_config_options = view_config[:options] || {}
        view_config_options.each do |attr, value|
          view.update_attribute(attr, value)
        end

        precision = obj[:precision] || 0
        if precision != 0
          view.update_attribute(:column_types, [''].concat(from_year.step(to_year, 5).map { |year| 'float' }))
        end

        view.reset_default_symbologies
          
        actions = view_config[:actions] || []
        actions.each do |action|
          view.add_action action.to_sym
        end
        puts 'view: ' + view.name

        fields = view_config[:field_mappings] || []

        fields.each do |field_config|
          yield("seeding #{view_name}", counter) if block_given?
          counter += row_size
          field_name = field_config[:field]
          year = field_config[:year]

          field_data = csv_data[field_name.downcase.to_sym]
          field_data.each_with_index do |value, idx|
            area_id = area_lookup[idx]
            if !area_id # no match area for this row
              next
            end

            rec = DemographicFact.where(
              view: view,
              year: year,
              statistic: stat,
              area_id: area_id
            ).first_or_create

            rec.update_attribute(:value, value.to_f.round(precision))
          end
        end
        puts "#{DemographicFact.where(view: view).count} facts"
      end
    end

    puts 'finished seeding'
    yield("processed") if block_given?
  end

  def self.prepare_county_uploading(source, file_path, from_year, to_year, geometry_base_year, &block)
    require 'csv'
    file_name = file_path
    csv_data = CSV.table(file_name) # read csv in table mode
     # pre-load years in database based on year_row_data value
    year_lookup = csv_data[:year] # area identification of each row
    years = year_lookup.uniq.sort

    data_level = :county
    data_hierarchy = [["county", ["subregion", "region"]]]

    view_template = {
      :actions => [:table, :map, :chart, :view_metadata, :edit_metadata],
      :options => {
        geometry_base_year: geometry_base_year,
        spatial_level: Area::AREA_LEVELS[:county],
        data_hierarchy: data_hierarchy,
        data_starts_at: DateTime.new(from_year),
        data_ends_at: DateTime.new(to_year),
        rows_updated_at: DateTime.now,
        data_levels: [Area::AREA_LEVELS[data_level]],
        topic_area: "Demographics",
        data_model: DemographicFact,
        columns: ['area'].concat(years.map { |year| year.to_s }),
        column_labels: ['County'].concat(years.map { |year| year.to_s }),
        column_types: [''].concat(years.map { |year| 'numeric' }),
        value_name: :value
      }
    }

    stats = {}
  
    SOURCE_UPLOAD_COUNTY_VIEW_SETS.each do |k, v| 
      name = k.to_s.titleize
      
      stat = {
        :name => name
      }
      # value in thousands
      stat[:scale] = 3 if k != :household_size

      set = {
        :statistic => stat,
        :view => Hash[view_template],
        :precision => v[:precision]
      }
      set[:view][:name] = "#{from_year}-#{to_year} #{name}"
      set[:view][:description] = v[:desc]
      set[:view][:field] = v[:prefix]
      
      stats[k] = set
    end

    # prepare configs for one source / file
    seeds_config = {
      #:file_name => file_path,
      :area_level => Area::AREA_LEVELS[data_level], #optional
      :area_value_column => data_level,
      #:year_value_column => 'YEAR',
      :statistics => []
    }

    SOURCE_UPLOAD_COUNTY_VIEW_SETS.keys.each do |stat_index|
      if !stat_index
        next
      end

      stat_config_data = stats[stat_index.to_s.strip.downcase.to_sym]
      if stat_config_data
        seeds_config[:statistics] << stat_config_data
      end
    end

    # start processing

    puts 'Source: ' + source.name

    yield('parsing file (take a while)...', 0) if block_given?

    area_level = seeds_config[:area_level]
    area_row_data = csv_data[seeds_config[:area_value_column].downcase.to_sym] # area identification of each row
    # pre-load the id of area in database based on area_row_data value
    area_lookup = []
    area_row_data.each do |area_value|
      area = Area.where(type: data_level, name: area_value.to_s.titleize, year: geometry_base_year).first

      if area
        area_lookup << area.id
      else
        area_lookup << nil
      end
    end

    row_size = year_lookup.size
    yield('count', stats.size * row_size) if block_given?

    counter = 0
    stats = seeds_config[:statistics]
    stats.each_with_index do |obj, index|
      counter = index * row_size
      stat_config = obj[:statistic]
      if stat_config
        stat = Statistic.find_or_create_by(name: stat_config[:name], scale: stat_config[:scale])
        stat_config.each do |attr, value|
          stat.update_attribute(attr, value)
        end
        puts 'statistic: ' + stat.name
      end

      view_config = obj[:view]
      if view_config && !view_config[:field].blank?
        view_name = view_config[:name]

        yield("creating view #{view_name}", counter) if block_given?

        view = View.where(name: view_name, source: source, statistic: stat).first_or_create
        view.update_attributes(data_model: DemographicFact, description: view_config[:desc])
        
        view_config_options = view_config[:options] || {}
        view_config_options.each do |attr, value|
          view.update_attribute(attr, value)
        end

        precision = obj[:precision] || 0
        if precision != 0
          view.update_attribute(:column_types, [''].concat(years.map { |year| 'float' }))
        end

        view.reset_default_symbologies
          
        actions = view_config[:actions] || []
        actions.each do |action|
          view.add_action action.to_sym
        end
        puts 'view: ' + view.name

        field_name = view_config[:field]
        field_data = csv_data[field_name.downcase.to_sym]
        field_data.each_with_index do |value, idx|
          yield("seeding #{view_name}", counter) if block_given? && (counter % 100 == 0)
          counter += 1
          area_id = area_lookup[idx]
          year = year_lookup[idx]
          unless area_id && year
            next
          end

          rec = DemographicFact.where(
            view: view,
            year: year,
            statistic: stat,
            area_id: area_id
          ).first_or_create

          rec.update_attribute(:value, value.to_f.round(precision))
        end
        
        puts "#{DemographicFact.where(view: view).count} facts"
      end
    end

    puts 'finished seeding 2040 sed county forecaset'
    yield("processed") if block_given?
  end
end