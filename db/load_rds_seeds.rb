# This seeding script is only executed when ENV['load_rds'] = true
# Dependency:
#   RDS replies on TMC geometry; so should have TMC table ready before running this script.
# Command params
#   YEAR 
#     required, e.g., YEAR=2013
#   MONTHS_TO_LOAD
#     required, e.g., MONTHS_TO_LOAD='4,5'  
#   RDS_FOLDER_PATH: 
#     the container path of RDS files
#     optional, default value: File.join(Rails.root, 'db', 'rds')
# A full sample command
#   rake db:seed load_rds=true YEAR=2013 MONTHS_TO_LOAD='4,8'

require 'csv'

# process data and seed into DB
def load_rds_seeds(seeds_config)
  year = seeds_config[:year]
  puts "start loading #{year} RDS data"
  
  #source
  source = Source.find_or_create_by(name: 'NPMRDS')
  source.update_attribute(:description, "National Performance Management Research Data Set")

  #view
  view = source.views.where(name: 'NPMRDS').first_or_create
  view.update_attribute(:data_model, SpeedFact)
  view.update_attribute(:description, "National Performance Management Research Data Set")
  view.add_action(:table)
  view.add_action(:map)
  view.add_action(:metadata)
  view.update_attribute(:columns, [
        'id', 'tmc', 'area', 'road', 'direction', 
        'year', 'month','day_of_week', 
        'hour', 'vehicle_class', 'speed'])
  view.update_attribute(:column_labels, [
        'ID', 'TMC', 'County', 'Road','Direction', 
        'Year', 'Month', 'Day of Week',
        'Hour',  'Vehicle Class',  'Speed'])
  view.update_attribute(:data_levels, ['TMC'])

  statistic = Statistic.find_or_create_by(name: 'Speed (mph)')
  view.update_attributes(statistic: statistic, value_name: :speed, row_name: :tmc, column_name: :hour)
  
  #data loading
  month_files = seeds_config[:month_files] || []
  month_files.each do |month_config|
    start_t = Time.now
    start_count = SpeedFact.count
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    load_month_rds_data(
      year,
      month_config[:month], 
      month_config[:file_name], 
      view,
      seeds_config[:column_names],
      seeds_config[:ref_column_names],
      seeds_config[:value_column_configs])
    ActiveRecord::Base.logger = old_logger
    puts "duration(s): #{(Time.now - start_t)}"
    puts "count of new records: #{(SpeedFact.count - start_count)}"
  end

  puts "finished seeding year #{year} RDS data"
end

def load_month_rds_data(year, month, source_file, view, column_names, ref_column_names, value_column_configs)
  puts "start seeding month #{month}"

  SpeedFact.where(view: view, year: year, month: month).delete_all # delete all previous data

  areas = {} # internal hash in memory, avoid multiple DB query on same record
  roads = {}
  tmcs = {} 

  county_level = Area::AREA_LEVELS[:county]
  day_col_name = column_names[:day_of_week].downcase.to_sym
  direction_col_name = column_names[:direction].downcase.to_sym
  tmc_col_name = ref_column_names[:tmc].downcase.to_sym
  area_col_name = ref_column_names[:area].downcase.to_sym
  road_name_col_name = ref_column_names[:road_name].downcase.to_sym
  road_number_col_name = ref_column_names[:road_number].downcase.to_sym
  
  hour_prefix = value_column_configs[:hour_prefix]
  vc_affix_hash = value_column_configs[:vc_affix]

  # precompute column names
  col_names_vc_values = []

  (1..24).each do |hour|
    col_names = []
    vc_affix_hash.each do |vc, affix|
      vc_value = SpeedFact.vehicle_classes[vc]
      col_name = (hour_prefix + hour.to_s + affix).downcase.to_sym
      col_names[vc_value] = col_name
    end
    col_names_vc_values[hour] = col_names
  end

  begin
    CSV.foreach(source_file, headers: true, return_headers: false,
                converters: :numeric, header_converters: :symbol) do |row|
      #  "area_id"
      area_name = row[area_col_name]
      if !area_name.blank?
        area = areas[area_name]
        if !area
          area = Area.where(name: area_name, type:county_level).first
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
          road = seed_single_road(road_name, road_number, direction)
          roads[road_index] = road
        end
      end

      #  "tmc_id"
      tmc_name = row[tmc_col_name]
      tmc = tmcs[tmc_name]
      if !tmc
        tmc = Tmc.where(name: tmc_name).first
        tmcs[tmc_name] = tmc
      end

      if !tmc # require TMC presense
        puts "match TMC not found for: #{tmc_name}"
        next
      end
      base_geometry_id = tmc.base_geometry_id

      #  "day_of_week"
      day_of_week_str = row[day_col_name] || ''
      day_of_week = SpeedFact.day_of_weeks[day_of_week_str.downcase]
      if !day_of_week
        puts "invalid day of week: #{day_of_week_str}"
        next
      end

      ActiveRecord::Base.transaction do
        (1..24).each do |hour|
          SpeedFact.vehicle_classes.values.each do |vc_value|
            # vc_affix_hash.each do |vc, affix|
            #   vc_value = SpeedFact.vehicle_classes[vc]
            #   col_name = hour_prefix + hour.to_s + affix
            #   speed = row[col_name.downcase.to_sym].to_i
            speed = row[col_names_vc_values[hour][vc_value]]
            
            if speed == 0 # skip NULL value
              next
            end

            SpeedFact.new(
                          view: view,
                          road: road,
                          direction: direction,
                          tmc: tmc,
                          year: year,
                          month: month,
                          hour: hour,
                          day_of_week: day_of_week,
                          vehicle_class: vc_value,
                          area: area,
                          base_geometry_id: base_geometry_id,
                          speed: speed
                          ).save
          end
        end
      end
    end
  rescue => e 
    puts e.message
    puts "Please check if file exists: #{source_file}"
    puts "If not, you may download it from wiki page: (Converted) Data Files for Seeding "
  end

  puts "finished seeding month #{month}"
end

def seed_single_road(road_name, road_number, dir)
  Road.where(
    name: road_name,
    number: road_number,
    direction: dir
  ).first_or_create
end

rds_folder_path = ENV['RDS_FOLDER_PATH'] || File.join(Rails.root, 'db', 'rds')
rds_year = ENV['YEAR']
if rds_year.blank?
  puts 'Please specify the RDS year.'
else
  rds_month_files = []
  months_to_load = ENV['MONTHS_TO_LOAD'] || ''

  months_to_load.split(',').each do |month|
    month_str = month.strip
    if month.to_i < 10
      month_str = '0' + month.strip
    end
    rds_month_files << {
      month: month.to_i,
      file_name: File.join(rds_folder_path, "rds_ne_#{month_str}_#{rds_year}.csv")
    }
  end

  seeds_config = {
    year: rds_year.to_i,
    month_files: rds_month_files,
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

  load_rds_seeds(seeds_config)
end
