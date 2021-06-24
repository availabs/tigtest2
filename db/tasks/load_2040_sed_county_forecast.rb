# Please make sure Areas table already has the area (counties) associated with the data source file to load
# Choose Statatistics to load
#   1. Check available stats by looking at AVAILABLE_STATISTICS hash keys
#   2. if only include specific statistic keys, use STATS_TO_LOAD environment variable
#     e.g., STATS_TO_LOAD='school_enrollment,total_employment'
# A full sample command
#   rake load_2040_sed_county_forecast
#   or,
#   rake load_2040_sed_county_forecast STATS_TO_LOAD='total_population,total_employment'

# process data and seed into DB
def load_sed_forecast_seeds(seeds_config)
  require 'csv'
  source_config = seeds_config[:source] || {}
  file_name = seeds_config[:file_name]
  stats = seeds_config[:statistics]

  source = Source.find_or_create_by(name: source_config[:name])
  source_config.each do |attr, value|
    source.update_attribute(attr, value)
  end
  
  if !source
    puts 'failed to create new source'
    return
  end

  puts 'Source: ' + source.name

  csv_data = CSV.table(file_name) # read csv in table mode
  area_level = seeds_config[:area_level]
  area_row_data = csv_data[seeds_config[:area_value_column].downcase.to_sym] # area identification of each row

  # pre-load the id of area in database based on area_row_data value
  area_lookup = []
  area_row_data.each do |area_value|
    area = Area.where(name: area_value.to_s.titleize).first

    if area
      area_lookup << area.id
    else
      area_lookup << nil
    end
  end

  # pre-load years in database based on year_row_data value
  year_lookup = csv_data[seeds_config[:year_value_column].downcase.to_sym] # area identification of each row

  stats.each do |obj|
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
      view = View.where(name: view_config[:name], source: source, statistic: stat).first
      if !view
        view = View.create(name: view_config[:name])
        view.update_attribute(:source, source)
        view.update_attribute(:statistic, stat)
      end
      view.update_attributes(description: view_config[:desc])
      
      view_config_options = view_config[:options] || {}
      view_config_options.each do |attr, value|
        view.update_attribute(attr, value)
      end
      precision = obj[:precision] || 0
      if precision == 2
        view.update_attribute(:column_types, [''].concat(2000.step(2040, 5).map { |year| 'float' }))
      end
        
      actions = view_config[:actions] || []
      actions.each do |action|
        view.add_action action.to_sym
      end
      puts 'view: ' + view.name

      # default symbology
      view.symbologies.destroy_all
      "#{view.data_model}SymbologyService".constantize.new(view).configure_symbology rescue nil

      field_name = view_config[:field]
      field_data = csv_data[field_name.downcase.to_sym]
      field_data.each_with_index do |value, index|
        area_id = area_lookup[index]
        year = year_lookup[index]
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
end

# available statistics to load
VIEW_SETS = {
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

VIEW_TEMPLATE = {
      :actions => [:table, :map, :chart, :metadata],
      :options => {
        spatial_level: Area::AREA_LEVELS[:county],
        data_hierarchy: [["county", ["subregion", "region"]]],
        data_starts_at: DateTime.new(2000),
        data_ends_at: DateTime.new(2040),
        rows_updated_at: DateTime.now,
        data_levels: [Area::AREA_LEVELS[:county]],
        topic_area: "Demographics",
        data_model: DemographicFact,
        columns: ['area'].concat(2000.step(2040, 5).map { |year| year.to_s }),
        column_labels: ['County'].concat(2000.step(2040, 5).map { |year| year.to_s }),
        column_types: [''].concat(2000.step(2040, 5).map { |year| 'numeric' }),
        value_name: :value
  }
}

AVAILABLE_STATISTICS = {}
  
VIEW_SETS.each do |k, v| 
  name = k.to_s.titleize
  
  stat = {
    :name => name
  }
  # value in thousands
  stat[:scale] = 3 if k != :household_size

  set = {
    :statistic => stat,
    :view => Hash[VIEW_TEMPLATE],
    :precision => v[:precision]
  }
  set[:view][:name] = "2000-2040 #{name}"
  set[:view][:description] = v[:desc]
  set[:view][:field] = v[:prefix]
  
  AVAILABLE_STATISTICS[k] = set
end

# prepare configs for one source / file
source_name = '2040 SED County Level Forecast Data'
sed_forecast_config = {
  :file_name => File.join(Rails.root, 'db', 'SED_2040_Adopted_County_Forecasts_Revised.csv'),
  :area_level => Area::AREA_LEVELS[:county], #optional
  :area_value_column => 'COUNTY',
  :year_value_column => 'YEAR',
  :source => {
    :name => source_name,
    :current_version => 1,
    :data_starts_at => DateTime.new(2000),
    :data_ends_at => DateTime.new(2040),
    :description => "NYMTC Socio-economic forecast data at county level ranging from 2000 to 2040.",
    :origin_url => "https://wiki.camsys.com/display/TIG/NYMTC+TIG+Public",
    :rows_updated_at => DateTime.now,
    :topic_area => "Demographics"
  },
  :statistics => []
}

# find stats to load
# check AVAILABLE_STATISTICS{} keys for available stat indexes to be used in seed cmd
if ENV["STATS_TO_LOAD"]
  load_set = ENV["STATS_TO_LOAD"].to_s.split(',') || []
else
  load_set = VIEW_SETS.keys
end

load_set.each do |stat_index|
  if !stat_index
    next
  end

  stat_config_data = AVAILABLE_STATISTICS[stat_index.to_s.strip.downcase.to_sym]
  if stat_config_data
    sed_forecast_config[:statistics] << stat_config_data
  end
end

puts 'start loading 2040 SED county forecast forecast data'
load_sed_forecast_seeds(sed_forecast_config)
