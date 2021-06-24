# This seeding script is only executed when ENV['load_bpm_2005_taz_forecast'] = true
#   Please make sure Areas table already has the area associated with the data source file to load
#   e.g., NYBPM_2005_TAZ_Forecast.csv is TAZ level based, then you need to have TAZ areas in Areas table
# Choose Statatistics to load
#   1. Check available stats by looking at AVAILABLE_STATISTICS hash keys
#   2. list statistic key in ENV cmd via STATS_TO_LOAD=[]
#     e.g., STATS_TO_LOAD='school_enrollment,total_employment'
# A full sample command
#   rake db:seed load_bpm_2005_taz_forecast=true STATS_TO_LOAD='school_enrollment,total_employment'

# process data and seed into DB
def load_bpm_forecast_seeds(seeds_config)
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
    area = Area.where(name: area_value.to_s).first

    if area
      area_lookup << area.id
    else
      area_lookup << nil
    end
  end

  stats.each do |obj|
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
        view.update_attribute(:column_types, [''].concat(2010.step(2040, 5).map { |year| 'float' }))
      end
        
      actions = view_config[:actions] || []
      actions.each do |action|
        view.add_action action.to_sym
      end
      puts 'view: ' + view.name

      fields = view_config[:field_mappings] || []

      fields.each do |field_config|
        field_name = field_config[:field]
        year = field_config[:year]

        field_data = csv_data[field_name.downcase.to_sym]
        field_data.each_with_index do |value, index|
          area_id = area_lookup[index]
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

  puts 'finished seeding nybpm 2005 taz forecaset'
end

# available statistics to load
VIEW_SETS = {
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

VIEW_TEMPLATE = {
      :actions => [:table, :map, :metadata],
      :options => {
        data_starts_at: DateTime.new(2010),
        data_ends_at: DateTime.new(2040),
        rows_updated_at: DateTime.now,
        data_levels: [Area::AREA_LEVELS[:taz]],
        topic_area: "Demographics",
        data_model: DemographicFact,
        columns: ['area'].concat(2010.step(2040, 5).map { |year| year.to_s }),
        column_labels: ['TAZ'].concat(2010.step(2040, 5).map { |year| year.to_s }),
        column_types: [''].concat(2010.step(2040, 5).map { |year| 'numeric' }),
        value_name: :value
  }
}

AVAILABLE_STATISTICS = {}
  
VIEW_SETS.each do |k, v| 
  name = k.to_s.titleize
  mappings = []
  (10..40).step(5) do |year|
    full_year = 2000 + year
    mappings << {
      :field => v[:prefix] + year.to_s,
      :year => full_year
    }
  end
  
  set = {
    :statistic => {
      :name => name
    },
    :view => Hash[VIEW_TEMPLATE],
    :precision => v[:precision]
  }
  set[:view][:name] = "2010-2040 #{name}"
  set[:view][:description] = v[:desc]
  set[:view][:field_mappings] = mappings
  
  AVAILABLE_STATISTICS[k] = set
end

# prepare configs for one source / file
bpm_forecast_config = {
  :file_name => File.join(Rails.root, 'db', 'NYBPM_2005_TAZ_Forecast.csv'),
  :area_level => Area::AREA_LEVELS[:taz], #optional
  :area_value_column => 'TAZ',
  :source => {
    :name => 'SED Forecast Data',
    :current_version => 1,
    :data_starts_at => DateTime.new(2010),
    :data_ends_at => DateTime.new(2040),
    :description => "NYMTC Socio-economic forecast data ranging from 2010 to 2040.",
    :origin_url => "https://wiki.camsys.com/display/TIG/NYMTC+TIG+Public",
    :rows_updated_at => DateTime.now,
    :topic_area => "Demographics"
  },
  :statistics => []
}

# find stats to load
# check AVAILABLE_STATISTICS{} keys for available stat indexes to be used in seed cmd
if ENV["STATS_TO_LOAD"]
  STATS_TO_LOAD = ENV["STATS_TO_LOAD"].to_s.split(',') || []
end
if STATS_TO_LOAD.count == 1 && STATS_TO_LOAD[0].strip.downcase == "all"
  load_set = VIEW_SETS.keys
else
  load_set = STATS_TO_LOAD
end

load_set.each do |stat_index|
  if !stat_index
    next
  end

  stat_config_data = AVAILABLE_STATISTICS[stat_index.to_s.strip.downcase.to_sym]
  if stat_config_data
    bpm_forecast_config[:statistics] << stat_config_data
  end
end

# rename NYBPM TAZ Forecast source to NYBPM Forecast
source = Source.where(name: 'NYBPM TAZ Forecast').first
if source
  source.update_attribute(:name, 'NYBPM Forecast')
end

puts 'start loading bpm 2005 taz forecast data'
load_bpm_forecast_seeds(bpm_forecast_config)
