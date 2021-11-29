# This seeding script is only executed when ENV['load_bpm_2020_taz_forecast'] = true
#   Please make sure Areas table already has the area associated with the data source file to load
#   e.g., NYBPM_2005_TAZ_Forecast.csv is TAZ level based, then you need to have TAZ areas in Areas table
# Choose Statatistics to load
#   1. Check available stats by looking at AVAILABLE_STATISTICS hash keys
#   2. list statistic key in ENV cmd via STATS_TO_LOAD=[]
#     e.g., STATS_TO_LOAD='school_enrollment,total_employment'
# A full sample command
#   rake db:seed load_bpm_2020_taz_forecast=true STATS_TO_LOAD='school_enrollment,total_employment'
#
# Available statistics to load from the CSV:
#   $ grep -E '[0-9][0-9]$' csv/2055SED_TAZ_TIG.columns | sed 's/[0-9][0-9]$//g' | sort -u 
#   Earn
#   EmpLF
#   EmpOff
#   EmpRet
#   EmpTot
#   EnrolK12_
#   EnrolUniv
#   HHInc
#   HHSize
#   Households
#   PopGQ
#   PopGQHmls
#   PopGQInst
#   PopGQOth
#   PopHH
#   PopTot

SED_TAZ_DATA_FILE_NAME = '2055SED_TAZ_TIG.csv'
SED_TAZ_DATA_FILE_PATH = File.join(Rails.root, 'db', SED_TAZ_DATA_FILE_NAME)

SOURCE = Source.find_by(name: '2055 SED TAZ Level Forecast Data');

FORECAST_FROM_YEAR = 2010
FORECAST_TO_YEAR = 2055

GEOMETRY_BASE_YEAR = 2020

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

puts SOURCE_UPLOAD_TAZ_VIEW_SETS.to_s

# =====================================================

def start_taz_upload(source, file_path, from_year, to_year, geometry_base_year)
  puts 'start_taz_upload'

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
    puts "view to create: #{from_year}-#{to_year} #{name}"
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

  puts "forecast_config: " + forecast_config.to_s 

  load_data_from_taz_csv(source, from_year, to_year, geometry_base_year, forecast_config)
end

def load_data_from_taz_csv(source, from_year, to_year, geometry_base_year, seeds_config)
  puts "load_data_from_taz_csv #{seeds_config[:file_name]}"
  puts "load_data_from_taz_csv #{seeds_config[:area_value_column].downcase.to_s}"

  data_level = :taz
  puts 'Source: ' + source.name

  require 'csv'
  file_name = seeds_config[:file_name]
  stats = seeds_config[:statistics]

  puts 'Loading CSV...'
  start = Time.now
  csv_data = CSV.table(file_name) # read csv in table mode
  finish = Time.now
  puts 'Loaded in ' + (start - finish).to_s
  
  puts "csv_data #{csv_data.length.to_s} #{csv_data.headers}"

  area_level = seeds_config[:area_level]
  area_row_data = csv_data[seeds_config[:area_value_column].downcase.to_sym] # area identification of each row

  puts "#{seeds_config[:area_value_column].downcase.to_sym}"
  puts "csv_data #{csv_data.length.to_s} new:#{area_row_data.length.to_s}"

  # pre-load the id of area in database based on area_row_data value
  area_lookup = []
  area_row_data.each do |area_value|
    
    area = Area.where(type: data_level, name: area_value.to_s, year: geometry_base_year).first

    #puts "Area: #{area} #{area_value.to_s}"

    if area
      #puts "Area: #{area.id}"
      area_lookup << area.id
    else
      area_lookup << nil
    end
  end

  row_size = area_row_data.size
  year_count = (to_year - from_year) / 5 + 1

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
      puts 'fields: ' +fields.to_s


      fields.each do |field_config|
        counter += row_size
        field_name = field_config[:field]
        year = field_config[:year]

        field_data = csv_data[field_name.downcase.to_sym]
        puts "#{field_name} #{field_data.length}"
        field_data.each_with_index do |value, idx|
          area_id = area_lookup[idx]
          if !area_id # no match area for this row
            puts "unmatched area #{area_id}"
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
end

ActiveRecord::Base.transaction do
  start_taz_upload(
    SOURCE,
    SED_TAZ_DATA_FILE_PATH,
    FORECAST_FROM_YEAR,
    FORECAST_TO_YEAR,
    GEOMETRY_BASE_YEAR
  )
end
