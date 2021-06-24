# This seeding script is only executed when ENV['load_acs_data'] = true
# This script will parse the Geography column and create Census Tract areas as needed

# process data and seed into DB
def load_acs_data_seeds(seeds_config)
  require 'csv'
  
  source_config = seeds_config[:source] || {}
  file_name = seeds_config[:file_name]

  use_field_difference_as_value = seeds_config[:use_field_difference_as_value]
  
  source = Source.find_or_create_by(name: source_config[:name])
  source_config.each do |attr, value|
    source.update_attribute(attr, value)
  end
  
  if !source
    puts 'failed to create new source'
    return
  end

  puts 'Source: ' + source.name

  stats_views = construct_stats(seeds_config[:statistics], source)
  
  csv_data = CSV.table(file_name) # read csv in table mode
  area_level = seeds_config[:area_level]

  # area identification of each row, parsed to construct census tract
  area_sym = seeds_config[:area_value_column].downcase.to_sym
  fips_sym = seeds_config[:area_fips_column].downcase.to_sym
  
  # process each row
  csv_data.each do |row|
    area = Area.parse(row[area_sym], area_level, row[fips_sym].to_i)

    stats_views.each do |hash|
      rec = ComparativeFact.where(view: hash[:view],
                                  area: area,
                                  base_statistic: hash[:base_statistic],
                                  statistic: hash[:statistic]
                                  ).first_or_create
      base_value = row[hash[:field_mappings][:base_field]]
      value = row[hash[:field_mappings][:field]]
      value = base_value - value if use_field_difference_as_value
      rec.update_attributes(base_value: base_value,
                            value: value)
    end
  end
end

def construct_stats statistic_configs, source
  stats_views = []
  statistic_configs.each do |hash|
    stat = create_statistic hash[:statistic]
    base_stat = create_statistic hash[:base_statistic]
    view = create_view(hash[:view], source, stat)
    stats_views << {
      statistic: stat,
      base_statistic: base_stat,
      view: view,
      field_mappings: hash[:field_mappings]}
  end
  stats_views
end

def create_statistic stat_config
  if stat_config
    stat = Statistic.find_or_create_by(name: stat_config[:name])
    stat_config.each do |attr, value|
      stat.update_attribute(attr, value)
    end
    puts 'statistic: ' + stat.name
  end
  stat
end

def create_view view_config, source, stat
  if view_config
    view = View.where(name: view_config[:name], source: source, statistic: stat).first
    if !view
      view = View.create(name: view_config[:name])
      view.update_attribute(:source, source)
      view.update_attribute(:statistic, stat)
    end
    view_config_options = view_config[:options] || {}
    view_config_options.each do |attr, value|
      view.update_attribute(attr, value)
    end

    actions = view_config[:actions] || []
    actions.each do |action|
      view.add_action action.to_sym
    end
    puts 'view: ' + view.name
  end
  view
end

# field mappings
# This symbol business is a crock, but there appears to be no easy way to call the
# same converter that CSV calls on it's headers, so directly including the converted
# header here.
# poverty_field_mappings =
#   {base_field:  :total_estimate_population_for_whom_poverty_status_is_determined,
#    field:  :below_poverty_level_estimate_population_for_whom_poverty_status_is_determined}

poverty_field_mappings = {base_field:  :hc01_est_vc01, field:  :hc02_est_vc01}

acs_source_config = {
    :name => 'ACS/Census Data',
    :current_version => 1,
    :description => 'Data derived from extracts from various tables available through American Fact Finder',
    :origin_url => "http://factfinder.census.gov/",
    :rows_updated_at => DateTime.now,
    :topic_area => "Comparative Socio-economics"
}

poverty_level_config = {
  :file_name => File.join(Rails.root, 'db', '31countiesACS_13_5YR_S1701.csv'),
  :area_level => :census_tract, 
  :area_value_column => 'Geography',
  :area_fips_column => 'Id2',
  :source => acs_source_config,
  :statistics => [
                  { statistic: {name: '% Below Poverty Level'},
                    base_statistic: {name: 'Base Population'},
                    view: {
                      name: 'Absolute and Relative Population Below Poverty Level',
                      actions: [:table, :map, :metadata],
                      options: {
                        description: "Poverty Status from ACS table S1701 5 year estimates for 2013.",
                        origin_url: "http://factfinder.census.gov/faces/tableservices/jsf/pages/productview.xhtml?pid=ACS_13_5YR_S1701&prodType=table",
                        rows_updated_at: DateTime.now,
                        topic_area: 'Comparative Socio-economics',
                        data_levels: [Area::AREA_LEVELS[:census_tract]],
                        data_model: ComparativeFact,
                        columns: ['enclosing_area', 'area_number_only', 'fips_code', 'base_value', 'value', 'percent'],
                        column_labels: ['County', 'Census Tract', 'FIPS', 'Population', 'Population Below Poverty', 'Percent Below Poverty'],
                        column_types: ['','','','numeric','numeric','percent'],
                        value_columns: ['value', 'percent'],
                        value_name: :value
                      }
                    },
                    field_mappings: poverty_field_mappings
                  }]
}

minority_field_mappings =
  {base_field:  :hc01_vc77,
   field:       :hc01_vc78}

# Value is White population, minority population is base_value - value
minority_config = {
  :file_name => File.join(Rails.root, 'db', '31countiesACS_13_5YR_DP05.csv'),
  :area_level => :census_tract, 
  :area_value_column => 'Geography',
  :area_fips_column => 'Id2',
  :use_field_difference_as_value => true,  
  :source => acs_source_config,
  :statistics => [
                  { statistic: {name: '% Minority'},
                    base_statistic: {name: 'Base Population'},
                    view: {
                      name: 'Absolute and Relative Minority Population',
                      actions: [:table, :map, :metadata],
                      options: {
                        description: 'Minority population from ACS table DP05 5 year estimates for 2013.',
                        origin_url: 'http://factfinder.census.gov/faces/tableservices/jsf/pages/productview.xhtml?pid=ACS_13_5YR_DP05&prodType=table',
                        rows_updated_at: DateTime.now,
                        topic_area: 'Comparative Socio-economics',
                        data_levels: [Area::AREA_LEVELS[:census_tract]],
                        data_model: ComparativeFact,
                        columns: ['enclosing_area', 'area_number_only', 'fips_code', 'base_value', 'value', 'percent'],
                        column_labels: ['County', 'Census Tract', 'FIPS', 'Population', 'Minority Population', 'Percent Minority'],
                        column_types: ['','','','numeric','numeric','percent'],
                        value_columns: ['value', 'percent'],
                        value_name: :value
                      }
                    },
                    field_mappings: minority_field_mappings
                  }]
}

load_acs_data_seeds poverty_level_config

load_acs_data_seeds minority_config
