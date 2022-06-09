class CountFact < ActiveRecord::Base
  belongs_to :count_variable
  belongs_to :transit_mode
  belongs_to :sector
  belongs_to :in_station, class_name: "TransitStation"
  belongs_to :out_station, class_name: "TransitStation"
  belongs_to :transit_agency
  belongs_to :transit_route
  belongs_to :location
  belongs_to :view

  def self.pivot?
    false
  end

  def self.exportable_as_shp?
    true
  end

  def self.styleable?
    true
  end

  def self.upload_extensions
    'mdb'
  end

  def hour
    if super
      '%02d:00 - %02d:00' % [super, super + 1]
    else
      super
    end
  end

  def count
    ApplicationController.helpers.number_with_delimiter('%g' % super)
  end

  def self.process_upload(io, view, year, month, extension, &block)
    return unless extension == '.mdb'

    # Clear existing facts
    yield('deleting') if block_given?
    where(view: view, year: year).delete_all
    
    processMdb(io, view, &block)
  end

  def self.processMdb(file, view)
    db = Mdb.open(file)

    # lookup table parsing
    # In general, preserve id values
    yield('parsing lookup tables') if block_given?
    Delayed::Worker.logger.debug('load CountVariables')
    variables_hash = {}
    all_vehicle_var_id = nil
    db[:Variables].each do |row|
      var_name = row[:VariableName]
      if var_name == 'All Vehicles'
        all_vehicle_var_id = row[:VariableID]
        next
      end

      var_desc = row[:VariableDescription]
      if var_name.index('Cars')
        var_name = 'Cars in Trains' 
        var_desc = 'Number of Cars in the Trains'
      end

      variable = CountVariable.find_or_create_by(name: var_name)
      variable.update_attributes(description: var_desc)
      variables_hash[row[:VariableID]] = variable.id if row[:VariableID]
    end

    Delayed::Worker.logger.debug('load TransitModes')
    modes_hash = {}
    db[:Mode].each do |row|
      mode_name = row[:ModeName]
      mode_name = 'Vehicles (Auto+Taxi+Trucks+Comm. Vans)' if mode_name.index('Vehicles') || mode_name == 'Auto-Taxi-Trucks-Commercial Vans'
      mode = TransitMode.find_or_create_by(name: mode_name)
      mode.update_attributes(type: row[:Type],
                             group: row[:GroupName])
      modes_hash[row[:ModeID]] = mode.id if row[:ModeID]
    end

    Delayed::Worker.logger.debug('load ModeVariable -> TransitMode#count_variables & CountVariable#transit_modes')
    db[:ModeVariable].each do |row|
      next if all_vehicle_var_id && row[:VariableID] == all_vehicle_var_id

      mode = TransitMode.find_by_id(modes_hash[row[:ModeID]])
      variable = CountVariable.find_by_id(variables_hash[row[:VariableID]]) 

      mode.count_variables << variable if mode && variable && !mode.count_variables.include?(variable)
    end

    Delayed::Worker.logger.debug('load Sectors')
    sectors_hash = {}
    db[:Sector].each do |row|
      sector = Sector.find_or_create_by(name: row[:SectorName])
      sector.update_attributes(counts: row[:Location_Counts],
                               group: row[:GroupName],
                               order: row[:SectorOrder])
      sectors_hash[row[:SectorID]] = sector.id if row[:SectorID]
    end

    Delayed::Worker.logger.debug('load Agencies')
    agencies_hash = {}
    db[:Agencies].each do |row|
      agency = TransitAgency.find_or_create_by(name: row[:AgencyName])
      agency.update_attributes(contact: row[:Contact])
      agencies_hash[row[:AgencyID]] = agency.id if row[:AgencyID]
    end

    Delayed::Worker.logger.debug('load TransitLines -> TransitRoute')
    routes_hash = {}
    db[:TransitLines].each do |row|
      route = TransitRoute.find_or_create_by(name: row[:TransitRoute])
      agency_id = agencies_hash[row[:AgencyID]]
      route.update_attributes(transit_agency_id: agency_id)
      routes_hash[row[:TransitID]] = {
        id: route.id,
        transit_agency_id: agency_id
      } if row[:TransitID]
    end

    Delayed::Worker.logger.debug('load Locations')
    locations_hash = {}
    db[:Location].each do |row|
      loc = Location.find_or_create_by(name: row[:LocationName])
      sector_id = sectors_hash[row[:SectorID]]
      loc.update_attributes(sector_id: sector_id,
                            latitude: row[:Latitude],
                            longitude: row[:Longitude],
                            surface_type: row[:Surface_Type])
      
      locations_hash[row[:LocationID]] = {
        id: loc.id,
        sector_id: sector_id
      } if row[:LocationID]
    end

    Delayed::Worker.logger.debug('load TransitLocation -> TransitStation')
    db[:TransitLocation].each do |row|
      station = row[:Inbound_Station]
      TransitStation.find_or_create_by(name: station) unless station.blank?
      station = row[:Outbound_Station]
      TransitStation.find_or_create_by(name: station) unless station.blank?
    end
    
    Delayed::Worker.logger.debug('load MasterCounts -> CountFact')
    # Collect CountFact columns to sanity check new facts.
    # No columns should be nil except possibly for in_station and out_station
    columns = CountFact.columns.collect {|c| c.name}
    columns.delete("in_station_id")
    columns.delete("out_station_id")

    incomplete_count = 0

    # counting
    yield('count', db[:MasterCounts].size) if block_given?

    db[:MasterCounts].each_with_index do |row, row_index|
      yield('processing', row_index) if block_given? && row_index % 100 == 0

      next if all_vehicle_var_id && row[:VariableID] == all_vehicle_var_id

      year = row[:Year].to_i
      hour = DateTime.parse(row[:Time]).hour
      count = row[:VariableCount].to_f
      
      location_hash = locations_hash[row[:LocationID]]
      if location_hash
        loc_id = location_hash[:id]
        sector_id = location_hash[:sector_id]
      end


      # TransitLocations yields in_station, out_station, transit_route, mode
      transit_location = db[:TransitLocation].select {|r| r[:TransitLocationID] == row[:TransitLocnID]}.first
      if transit_location
        route_hash = routes_hash[transit_location[:TransitID]]
        if route_hash
          route_id = route_hash[:id]
          transit_agency_id = route_hash[:transit_agency_id]
        end
        in_station = TransitStation.find_by(name: transit_location[:Inbound_Station])
        out_station = TransitStation.find_by(name: transit_location[:Outbound_Station])
        loc_mode_id = transit_location[:ModeID]
      else
        Delayed::Worker.logger.debug("unrecognized transit location: #{row[:TransitLocnID]}")
      end
      
      fact = CountFact.find_or_create_by(
        view: view,
        year: year, direction: row[:Direction], hour: hour,
        count_variable_id: variables_hash[row[:VariableID]],
        location_id: loc_id, sector_id: sector_id,
        transit_mode_id: modes_hash[loc_mode_id],
        transit_route_id: route_id,
        transit_agency_id: transit_agency_id,
        in_station: in_station, out_station: out_station
      )
      fact.update_attributes(count: count)
      
      unless columns.all? {|c| fact.send(c) != nil}
        Delayed::Worker.logger.debug("Incomplete CountFact: #{fact.id} (Detail ID: #{row[:DetailID]})")
        incomplete_count += 1
      end
    end
    Delayed::Worker.logger.debug("there were #{incomplete_count} incomplete entries")

    cars = CountVariable.where(CountVariable.arel_table[:name].matches('%Cars%')).first
    vehicles = CountVariable.where(name: 'Vehicles', description: 'Number of Vehicles').first_or_create
    veh_mode = TransitMode.where(TransitMode.arel_table[:name].matches("%Vehicles%")).first

    CountFact.where(count_variable: cars, transit_mode: veh_mode)
      .update_all(count_variable_id: vehicles.id)

    Delayed::Worker.logger.debug("remove 'All Vehicles' facts")
    var = CountVariable.find_by(name: "All Vehicles")
    if var
      CountFact.delete_all(count_variable: var)
      var.delete
    end

    yield('processed') if block_given?
  end

  def self.get_base_data(view)
    includes(:count_variable,
             :transit_mode,
             :sector,
             :in_station,
             :out_station,
             :transit_agency,
             :transit_route,
             :location)
      .references(:count_variable,
                  :transit_mode,
                  :sector,
                  :in_station,
                  :out_station,
                  :transit_agency,
                  :transit_route,
                  :location)
      .where(view: view)
  end
    
  # Select facts where percent is >= lower and < upper
  # Assumes facts all have same view
  def self.range_select(facts, lower, upper)
    if lower.blank? && upper.blank?
      facts
    else
      unless lower.blank?
        lower = lower.to_f
        facts = facts.where('count >= ?', lower)
      end
      unless upper.blank?
        upper = upper.to_f
        facts = facts.where('count <= ?', upper)
      end
      facts
    end
  end

  def self.get_data(view, year, hour, transit_mode, transit_direction, area, lower=nil, upper=nil)
    if !(year && hour && transit_mode && transit_direction)
      nil
    else
      
      query_hash = {
        year: year.to_i, 
        hour: hour, 
        transit_mode: transit_mode,
        direction: transit_direction
      }

      print '--------------------------'
      print hour 
      print '--------------------------'
      

      base = self.joins(:location, :sector, :transit_mode, :transit_route, :count_variable).where(query_hash).select(
          "locations.latitude as lat",
          "locations.longitude as lng",
          "locations.id as loc_id",
          "locations.name as loc_name",
          "sectors.name as sector_name",
          "transit_modes.name as mode_name",
          "count_variables.name as var_name",
          "transit_routes.name as route_name",
          "count_facts.id",
          "count_facts.hour",
          :count
          )
      if area && area.is_study_area?
        base = base.where("ST_Intersects(?, ST_SetSRID(ST_MakePoint(locations.longitude, locations.latitude), 4326))", area.base_geometry.try(:geom))
      end

      self.range_select(base, lower, upper)

    end
  end

  def self.aggregate(view, year = nil, count_variable_id = nil, direction = nil, sector_id = nil, mode_id = nil, series = :direction, group_by_hour = true, agg_function = :sum, agg_by = :count)
    base = CountFact.where(view: view)

    if series.blank?
      group_by = :hour
    else
      group_by = case series.to_sym
      when :direction

        [:direction]
      when :sector
        base = base.joins(:sector)
        ["sectors.name"]
      when :transit_mode
        base = base.joins(:transit_mode)
        ["transit_modes.name"]
      end

      group_by.unshift(:hour) if group_by_hour 
    end

    base = base.select(group_by).group(group_by)

    base = base.where(year: year) if year
    
    base = base.where(count_variable_id: count_variable_id) if count_variable_id

    if mode_id && mode_id >= 0
      base = base.where(transit_mode_id: mode_id)
    end

    base = base.where(direction: direction) unless direction.blank? || direction == 'either'

    if sector_id && sector_id >= 0
      base = base.where(sector_id: sector_id)
    end

    base = case agg_function.downcase.to_sym
    when :sum
      base.sum(agg_by)
    when :average
      base.average(agg_by)
    end
    
    base
  end  


  def self.sortable_searchable_columns(view)
    view.columns.collect do |col|
      case col
      when 'direction', 'year', 'hour', 'count'
        "CountFact.#{col}"
      when 'in_station', 'out_station'
        'TransitStation.name'
      else
        "#{col.camelize}.name"
      end
    end
  end        

  def self.to_csv(view)
    CSV.generate do |csv|
      csv << [view.title] if view
      csv << view.columns.collect {|c| c.titleize}
      get_base_data(view).each do |fact|
        row = []
        view.columns.each do |col|
          row << fact.send(col)
        end
        csv << row
      end
    end
  end
end
