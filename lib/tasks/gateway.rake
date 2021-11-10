namespace :gateway do
  desc "Split 2040 Population Forecast view into County and TAZ views"
  task create_2040_taz_sed_view: :environment do
    require File.join(Rails.root, 'db', 'tasks/create_2040_taz_sed_view.rb')
  end

  desc "Clean up view data_levels to support one level"
  task clean_up_view_data_levels: :environment do
    require File.join(Rails.root, 'db', 'tasks/clean_up_view_data_levels.rb')
  end

  desc "Load or update area geometries"
  task load_area_geometry: :environment do
    require File.join(Rails.root, 'db', 'area_geometry_seeds.rb')
  end

  desc "Clean up duplicated road records and speed_fact road references"
  task clean_up_roads: :environment do
    require File.join(Rails.root, 'db', 'tasks/clean_up_roads.rb')
  end

  desc "Load Hub Bound Data"
  task load_hub_data: :environment do
    require File.join(Rails.root, 'db', 'tasks/load_hub_bound_data.rb')
  end

  desc "Load ACS Data"
  task load_acs_data: :environment do
    require File.join(Rails.root, 'db', 'acs_data_seeds.rb')
  end

  desc "Split 'Metadata' action into 'Edit Metadata' and 'View Metadata'"
  task split_metadata_action: :environment do
    require File.join(Rails.root, 'db', 'tasks/split_metadata_action.rb')
  end

  desc "Update View spatial_level and data_hierarchy"
  task update_view_spatial_level: :environment do
    require File.join(Rails.root, 'db', 'tasks/update_view_spatial_level.rb')
  end

  desc "Rename 'Agency' role to 'Agency User' and add 'Agency Admin' role"
  task alter_agency_roles: :environment do
    require File.join(Rails.root, 'db', 'tasks/alter_agency_roles.rb')
  end

  desc "Seed view symbologies and move hard-coded configs to symbology and associated models"
  task seed_view_symbologies: :environment do
    require File.join(Rails.root, 'db', 'tasks/seed_view_symbologies.rb')
    puts 'view symbologies updated'
  end

  desc "Change default_column_index using column.name instead of column.id"
  task use_column_name_as_index: :environment do
    require File.join(Rails.root, 'db', 'tasks/use_column_name_as_index.rb')
    puts 'symbology default_column_index updated'
  end

  desc "Update default symbologies for count_fact and comparative_fact"
  task update_count_and_comparative_fact_symbologies: :environment do
    require File.join(Rails.root, 'db', 'tasks/update_count_and_comparative_fact_symbologies.rb')
    puts 'count fact and comparative fact symbologies updated'
  end

  desc "Update Hub bound travel data private ferry mode coordinates"
  task update_hub_private_ferry_coords: :environment do
    require File.join(Rails.root, 'db', 'tasks/update_hub_private_ferry_coords.rb')
    puts 'Hub bound travel data private ferry mode coordinates updated'
  end

  desc "Update Household Size view map symbology number formatter with 2 decimal digits"
  task update_household_size_symbology_number_formatter: :environment do
    require File.join(Rails.root, 'db', 'tasks/update_household_size_symbology_number_formatter.rb')
    puts 'Household Size view map symbology number formatter updated'
  end

  desc "Update all Sources/Views to have default Access Controls"
  task create_access_controls: :environment do
    require File.join(Rails.root, 'db', 'tasks/create_access_controls.rb')
    puts 'Access Controls created.'
  end

  desc "Update Hub Bound data to clean up Vehicles"
  task update_hub_bound_data: :environment do
    require File.join(Rails.root, 'db', 'tasks/update_hub_bound_data.rb')
    puts 'Hub Bound data updated.'
  end

  desc "Load 2040 SED County level forecast data"
  task load_2040_sed_county_forecast: :environment do
    require File.join(Rails.root, 'db', 'tasks/load_2040_sed_county_forecast.rb')
    puts '2040 SED County level forecast data loaded.'
  end

  desc "Load 2055 SED TAZ level forecast data"
  task load_bpm_2055_taz_forecast: :environment do
    require File.join(Rails.root, 'db', 'bpm_2020_taz_forecast_seeds.rb')
    puts '2055 SED TAZ level forecast data loaded'
  end

  desc "Create Speed Fact partitions and move data"
  task partition_speed_facts: :environment do
    require File.join(Rails.root, 'db', 'tasks/create_speed_fact_partitions.rb')
    puts 'Speed Facts Partitioned.'
  end

  desc "Add statistic scales for 2040 SED county forecast views"
  task add_2040_sed_county_forecaset_statistic_scale: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_2040_sed_county_forecaset_statistic_scale.rb')
    puts 'Added statistic scales for 2040 SED county forecast views'
  end

  desc "Remove 'download' from the list of View actions"
  task remove_download_action: :environment do
    require File.join(Rails.root, 'db', 'tasks/remove_download_action.rb')
    puts 'Removed "download" action'
  end

  desc "Migrate map layer configurations to database"
  task migrate_layer_configs_to_db: :environment do
    require File.join(Rails.root, 'db', 'tasks/migrate_layer_configs_to_db.rb')
    puts 'Map layer configurations been migrated to database'
  end

  desc "Update existing TMCs year as 2013"
  task seed_tmc_year_as_2013: :environment do
    require File.join(Rails.root, 'db', 'tasks/seed_tmc_year_as_2013.rb')
    puts 'TMCs year updated'
  end

  desc "Seed area years"
  task seed_area_years: :environment do
    require File.join(Rails.root, 'db', 'tasks/seed_area_years.rb')
    puts 'Area years seeded'
  end

  desc "Seed geometry_base_year to Views"
  task seed_view_geometry_base_year: :environment do
    require File.join(Rails.root, 'db', 'tasks/seed_view_geometry_base_year.rb')
    puts 'Seeded geometry_base_year to Views'
  end

  desc "Import TMC geoJSON: 'load_tmc file=tmc_2014 year=2014'"
  task load_tmc: :environment do
    require File.join(Rails.root, 'db', 'tasks/load_tmc.rb')
  end

  desc "Create SpeedFact partitions for given year."
  task add_speed_fact_partitions: :environment do
    require 'gateway_monkey_patch_postgres.rb'
    require 'gateway_reader.rb'

    year = ENV['year'].to_i
    partitions = [year]
    (1..12).each do |month|
      partitions << [year, month]
    end
    print partitions
    puts
    SpeedFact.create_new_partition_tables(partitions)
  end

  desc "Import NPMRDS data: 'load_rds year=2014 months=all' or 'months=\"1,2,3\"'"
  task load_rds: :environment do
    require File.join(Rails.root, 'db', 'tasks/load_rds.rb')
  end

  desc "Add TMC 2014 map layer configuration to database"
  task add_2014_tmc_layer: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_2014_tmc_layer.rb')
    puts 'TMC 2014 map layer added to database'
  end

  desc "Enable 'watch' action for Views"
  task enable_watch_action_for_views: :environment do
    require File.join(Rails.root, 'db', 'tasks/enable_watch_action_for_views.rb')
    puts "'Watch' task has been enabled for all Views"
  end

  desc "Update TMC Index: Significantly improves the speed of sorting SpeedFacts by Tmc"
  task update_tmc_index: :environment do
    Tmc.transaction do
      start_index = Tmc.maximum(:index) + 1;
      Tmc.where(index: nil).order(:name).each_with_index {|tmc, i| tmc.update_attributes(index: start_index + i) }
      puts "Updated TMC index"
    end
  end

  desc "Ensure that a NYMTC agency exists, and that all Sources belong to some agency"
  task ensure_sources_have_agencies: :environment do
    require File.join(Rails.root, 'db', 'tasks/ensure_sources_have_agencies.rb')
    puts 'Sources updated.'
  end

  desc "Load RTP Project data"
  task load_rtp_project_data: :environment do
    require File.join(Rails.root, 'db', 'tasks/load_rtp_project_data.rb')
    puts "Loaded RTP project data"
  end

  desc "Load TIP Project data"
  task load_tip_project_data: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    require File.join(Rails.root, 'db', 'tasks/load_tip_project_data.rb')
    puts "Loaded TIP project data"
  end

  desc "Load UPWP Project data"
  task load_upwp_data: :environment do
    require File.join(Rails.root, 'db', 'tasks/load_upwp_data.rb')
    puts "Loaded UPWP project data"
  end

  desc "Load TRANSCOM Link data"
  task load_xcom_link_data: :environment do
    Link.loadCSV(File.join(Rails.root, 'db', 'LinkConfig_NYMTC_TIG.csv'))
  end

  desc "Load TRANSCOM Link geometry"
  task load_xcom_link_geometry: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    Link.loadGeoJSON(File.join(Rails.root, 'public/data', 'transcom_link.geojson'))
  end

  desc "Ensure an 'Upload' action exists"
  task enable_upload_action: :environment do
    Action.where(name: "upload").first_or_create
    puts "'Upload' action enabled"
  end

  desc "Create initial LinkSpeedFact partitions"
  task create_link_speed_facts_infrastructure: :environment do
    require 'gateway_monkey_patch_postgres.rb'
    require 'gateway_reader.rb'

    LinkSpeedFact.create_infrastructure
    LinkSpeedFact.create_new_partition_tables([2014, 2015])
  end

  desc "Create initial LinkSpeedFact source and view"
  task add_link_speed_view: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_link_speed_facts.rb')
  end

  desc "Add initial linkSpeedFact data: year, month, extension = '.zip'"
  task add_link_speed_facts: :environment do
    year = ENV['year']
    month = ENV['month']
    extension = ENV['extension'] || '.zip'
    if year.blank? || month.blank?
      puts "Please specify both year and month"
    else
      require 'zip'

      puts "Loading TRANSCOM data @ #{Time.now.strftime('%I:%M:%S')}"
      filename = File.join(Rails.root,"db/transcom/NYMTC_#{year}_#{month}_6#{extension}")
      if File.exist? filename
        puts "Will load #{filename}"
        view = View.find_by(data_model: YAML::dump(LinkSpeedFact))
        LinkSpeedFact.loadCSV(filename, view, year.to_i, month.to_i, extension) do |stage, row_count|
          puts "count: #{row_count * 10} @ #{Time.now.strftime('%I:%M:%S')}" if row_count % 10000 == 0
        end
      else
        puts "Could not find #{filename}"
      end
      puts "Loaded TRANSCOM data @ #{Time.now.strftime('%I:%M:%S')}"
    end
  end

  desc "Add TRANSCOM LINK map layer configuration to database"
  task add_link_layer: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_link_layer.rb')
    puts 'TRANSCOM LINK map layer added to database'
  end

  desc "Add Project columns to UPWP data"
  task add_project_columns: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_project_columns.rb')
    puts "Project columns added"
  end

  desc "Update existing MapBox Urls"
  task update_mapbox_urls: :environment do
    require File.join(Rails.root, 'db', 'tasks/update_mapbox_urls.rb')
    puts 'MapBox Urls updated'
  end

  desc "Update Counter Cache for UPWP Projects"
  task update_upwp_counter_cache: :environment do
    UpwpProject.find_each { |project| UpwpProject.reset_counters(project.id, :upwp_related_contracts) }
    puts 'Counter Caches for UPWP Projects have been updated'
  end

  desc "Add counter cache column to UPWP Projects table"
  task add_counter_cache_column: :environment do
    upwp_view = UpwpProject.first.view
    upwp_view.columns << :num_contracts
    upwp_view.column_types << ""
    upwp_view.column_labels << "No. of Contracts"
    upwp_view.save!
    puts 'Counter Caches for UPWP Projects have been updated'
  end

  desc "Load BPM Performance Measure data"
  task load_bpm_perf_measures: :environment do
    require File.join(Rails.root, 'db', 'tasks/load_bpm_perf_measure_data.rb')
    puts 'Perf Measures Loaded'
  end

  desc "Add the 'Copy' action to Views"
  task enable_copy_action: :environment do
    copy_action = Action.where(name: "copy").first_or_create
    View.find_each { |view| view.roles << copy_action if !view.roles.include?(copy_action) }
    puts "'Copy' action enabled"
  end

  desc "Clears 'data starts/ends at' columns that are equal in value for all Views"
  task clear_invalid_data_endpoints: :environment do
    View.where("data_starts_at = data_ends_at").each { |view|
      view.update_attributes(data_starts_at: nil, data_ends_at: nil)
      puts "'#{view.name}' has been reset"
    }
    puts "--- Invalid data endpoints have been reset ---"
  end

  desc "Flag existing symbologies as default"
  task flag_symbologies_as_default: :environment do
    Symbology.update_all(is_default: true)
    puts 'Finished flagging symbologies as default'
  end

  desc "Define default symbology for PerformanceMeasuresFact model"
  task define_performance_measures_symbology: :environment do
    View.where(data_model: YAML::dump(PerformanceMeasuresFact)).each do | view |
      PerformanceMeasuresFactSymbologyService.new(view).configure_symbology rescue nil
    end
    puts 'PerformanceMeasuresFact model default symbologies are defined'
  end

  desc "Update value_columns for ACS and BPM dataset"
  task update_value_columns_for_acs_bpm: :environment do
    View.where(data_model: YAML::dump(ComparativeFact)).update_all(value_columns: ['value', 'percent'])
    View.where(data_model: YAML::dump(PerformanceMeasuresFact)).update_all(value_columns: ["vehicle_miles_traveled", "vehicle_hours_traveled", "avg_speed"])
    puts 'Value columns are updated for ACS and BPM views.'
  end

  desc "Correct existing Views that have serialized Arrays as value_columns"
  task fix_view_value_columns: :environment do
    comparative_fact_view_ids = ComparativeFact.all.map { |cf| cf.view_id unless cf.view.nil? }.uniq.compact
    comparative_fact_view_ids.each do |v_id|
      view = View.find(v_id)
      view.update_attribute('value_columns', { view.columns[-3] => view.column_labels[-3], view.columns[-1] => view.column_labels[-1] })
    end
    puts 'Views with incorrect value_columns have been fixed.'
  end

  desc "Rollback 'fix_view_value_columns' task"
  task rollback_view_value_columns_change: :environment do
    comparative_fact_view_ids = ComparativeFact.all.map { |cf| cf.view_id unless cf.view.nil? }.uniq.compact
    comparative_fact_view_ids.each do |v_id|
      view = View.find(v_id)
      view.update_attribute('value_columns', [view.columns[-3], view.columns[-1]])
    end
    puts 'Views with incorrect value_columns have been fixed.'
  end

  desc "Add chart action to Hub bound"
  task add_chart_to_hub_bound_views: :environment do
    View.where(data_model: YAML::dump(CountFact)).each do |view|
      view.add_action :chart
    end
    puts 'Hub Bound views now have chart action.'
  end

  desc "Enable 2010 TAZ boundary"
  task enable_2010_taz_boundary: :environment do
    require File.join(Rails.root, 'db', 'tasks/enable_2010_taz_boundary.rb')
    puts '2010 TAZ Boundary enabled'
  end

  desc "Enable 2012 TAZ boundary"
  task enable_2012_taz_boundary: :environment do
    require File.join(Rails.root, 'db', 'tasks/enable_2012_taz_boundary.rb')
    puts '2012 TAZ Boundary enabled'
  end

  desc "Enable 2020 TAZ boundary"
  task enable_2020_taz_boundary: :environment do
    require File.join(Rails.root, 'db', 'tasks/enable_2020_taz_boundary.rb')
    puts '2020 TAZ Boundary enabled'
  end


  desc "Seed existing supported geometry versions"
  task seed_geometry_versions: :environment do
    require File.join(Rails.root, 'db', 'tasks/seed_geometry_versions.rb')
    puts 'Geometry versions seeded'
  end

  desc "Add 2015 TMC map layer configuration: a dupe of tmc_2014 config"
  task add_2015_tmc_map_config: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_2015_tmc_map_config.rb')
    puts 'TMC 2015 config added'
  end

  desc "Seed existing NPMRDS data vs TMC version mappings"
  task seed_npmrds_data_tmc_version_mappings: :environment do
    require File.join(Rails.root, 'db', 'tasks/seed_npmrds_data_tmc_version_mappings.rb')
    puts 'Version mappings seeded'
  end

  desc "add 2015 TMC into base_geometry_version"
  task add_2015_tmc_geometry_version: :environment do
    BaseGeometryVersion.where(category: 'tmc', version: '2015').first_or_create
    tmc_version = SpeedFactTmcVersionMapping.find_by(data_year: 2015)
    if tmc_version
      tmc_version.update(tmc_year: 2015)
    else
      SpeedFactTmcVersionMapping.create(data_year: 2015, tmc_year: 2015)
    end
    puts '2015 TMC version added'
  end

  desc "Tweak hub bound columns"
  task move_year_as_first_column_for_hub_bound: :environment do
    View.where(data_model: YAML::dump(CountFact)).each do |v|
      v.columns = ['year', 'count_variable', 'count','transit_route', 'transit_mode', 'in_station', 'out_station', 'direction', 'location', 'sector', 'hour', 'transit_agency']
      v.column_labels = ["Year", "Count Variable", "Count", "Route", "Mode", "In Station", "Out Station", "Direction", "Location", "Sector", "From - To", "Transit Agency"]
      v.column_types = ['text-right', '', 'text-right','', '', '', '', '', '', '', 'text-center', '']

      v.save
    end
  end

  desc "Add BPM Highway Network layer configuration to database"
  task add_bpm_highway_layer: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_bpm_highway_layer.rb')
    puts 'BPM Highway Network layer added to database'
  end

  desc "Add 2016 TMC layer"
  task add_2016_tmc_layer: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_2016_tmc_layer.rb')
    puts '2016 TMC layer added to database'
  end

  desc "Correcting Its ptype as ITS, and update TIP&RTP projects ptype_id accordingly"
  task update_project_its_ptype: :environment do
    its_ptype = Ptype.find_by_name('Its')
    its_cap_type = Ptype.find_by_name('ITS')
    if its_ptype.present?
      if its_cap_type.nil?
        its_ptype.name = 'ITS'
        its_ptype.save
      else
        RtpProject.where(ptype: its_ptype).update_all(ptype_id: its_cap_type.id)
        TipProject.where(ptype: its_ptype).update_all(ptype_id: its_cap_type.id)
        UniqueValueColorScheme.where(value: 'Its').update_all(value: 'ITS', label: 'ITS')
        its_ptype.destroy
      end
    end

    puts 'Its ptype is now ITS'
  end

  desc "Add 2017 TMC configurations"
  task add_2017_npmrds_configs: :environment do
    require File.join(Rails.root, 'db', 'tasks/add_2017_npmrds_configs.rb')
    puts '2017 NPMRDS configs added'
  end

  desc "Update BPM column labels "
  task update_bpm_perf_measure_column_labels: :environment do
    View.where(data_model: YAML::dump(PerformanceMeasuresFact)).update_all(column_labels: ['County', 'VMT (in Thousands)', 'VHT (in Thousands)', 'Avg. Speed (Miles/Hr)'])
    puts 'Updated'
  end

  desc "Support chart in ACS views "
  task support_acs_chart: :environment do
    views = View.where(data_model: YAML::dump(ComparativeFact))
    views.each do |v|
      v.add_action 'chart'
    end
    views.update_all(data_hierarchy: [["census_tract", "county", ["subregion", "region"]]])


    puts 'Chart enabled for ACS'
  end

  desc "Update Hub Bound data column labels "
  task update_hub_bound_data_column_labels: :environment do
    View.where(data_model: YAML::dump(CountFact)).update_all(column_labels: ["Year", "Count Variable", "Count", "Route", "Mode", "In Station", "Out Station", "Direction", "Location", "Sector", "From - To", "Transit Agency"])
    puts 'Updated'
  end

  desc "Remove columns from RTP "
  task remove_infra_category_from_rtp_views: :environment do
    new_columns = ["rtp_id", "description", "year", "estimated_cost", "ptype", "plan_portion", "sponsor", "county"]
    new_labels = ["RTP ID",
      "Description",
      "Year",
      "Estimated Cost",
      "Project Type",
      "Plan Portion",
      "Sponsor",
      "County"]
    new_col_types = ["", "", "", "millions", "", "", "", ""]

    rtp_views = View.where(data_model: YAML::dump(RtpProject))
    rtp_views.update_all(columns: new_columns)
    rtp_views.update_all(column_labels: new_labels)
    rtp_views.update_all(column_types: new_col_types)
  end
end
