# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181016233700) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "postgis_topology"

  create_table "access_controls", force: true do |t|
    t.integer  "source_id"
    t.integer  "view_id"
    t.integer  "agency_id"
    t.integer  "user_id"
    t.string   "role"
    t.boolean  "show"
    t.boolean  "download"
    t.boolean  "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "actions", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "actions", ["name", "resource_type", "resource_id"], :name => "index_actions_on_name_and_resource_type_and_resource_id"
  add_index "actions", ["name"], :name => "index_actions_on_name"

  create_table "agencies", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "area_enclosures", id: false, force: true do |t|
    t.integer "enclosing_area_id", null: false
    t.integer "enclosed_area_id",  null: false
  end

  add_index "area_enclosures", ["enclosed_area_id", "enclosing_area_id"], :name => "index_area_enclosures_on_enclosed_area_id_and_enclosing_area_id", :unique => true
  add_index "area_enclosures", ["enclosing_area_id", "enclosed_area_id"], :name => "index_area_enclosures_on_enclosing_area_id_and_enclosed_area_id", :unique => true

  create_table "areas", force: true do |t|
    t.string   "name"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "size"
    t.integer  "base_geometry_id"
    t.integer  "fips_code",        limit: 8
    t.integer  "year"
    t.integer  "user_id"
    t.text     "description"
    t.boolean  "published",                  default: false
  end

  add_index "areas", ["base_geometry_id"], :name => "index_areas_on_base_geometry_id"
  add_index "areas", ["fips_code"], :name => "index_areas_on_fips_code"
  add_index "areas", ["user_id"], :name => "index_areas_on_user_id"

  create_table "base_geometries", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "geom",       limit: {:srid=>4326, :type=>"geometry"}
  end

  add_index "base_geometries", ["geom"], :name => "index_base_geometries_on_geom", :spatial => true

  create_table "base_geometry_versions", force: true do |t|
    t.string   "category"
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "base_overlays", force: true do |t|
    t.string   "overlay_type"
    t.text     "properties"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "base_geometry_id"
  end

  add_index "base_overlays", ["base_geometry_id"], :name => "index_base_overlays_on_base_geometry_id"

  create_table "bpm_summary_facts", force: true do |t|
    t.integer  "view_id"
    t.integer  "area_id"
    t.integer  "year"
    t.string   "orig_dest"
    t.string   "purpose"
    t.string   "mode"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bpm_summary_facts", ["area_id"], :name => "index_bpm_summary_facts_on_area_id"
  add_index "bpm_summary_facts", ["mode"], :name => "index_bpm_summary_facts_on_mode"
  add_index "bpm_summary_facts", ["orig_dest"], :name => "index_bpm_summary_facts_on_orig_dest"
  add_index "bpm_summary_facts", ["purpose"], :name => "index_bpm_summary_facts_on_purpose"
  add_index "bpm_summary_facts", ["view_id"], :name => "index_bpm_summary_facts_on_view_id"
  add_index "bpm_summary_facts", ["year"], :name => "index_bpm_summary_facts_on_year"

  create_table "columns", force: true do |t|
    t.string   "name",         null: false
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "symbology_id"
  end

  add_index "columns", ["symbology_id"], :name => "index_columns_on_symbology_id"

  create_table "comments", force: true do |t|
    t.integer  "user_id"
    t.string   "subject"
    t.text     "text"
    t.integer  "source_id"
    t.integer  "view_id"
    t.integer  "app"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "blocked_by_id"
    t.boolean  "admin_only",    default: false
  end

  add_index "comments", ["source_id"], :name => "index_comments_on_source_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"
  add_index "comments", ["view_id"], :name => "index_comments_on_view_id"

  create_table "comparative_facts", force: true do |t|
    t.integer  "view_id"
    t.integer  "area_id"
    t.integer  "statistic_id"
    t.integer  "base_statistic_id"
    t.float    "value"
    t.float    "base_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comparative_facts", ["area_id"], :name => "index_comparative_facts_on_area_id"
  add_index "comparative_facts", ["base_statistic_id"], :name => "index_comparative_facts_on_base_statistic_id"
  add_index "comparative_facts", ["statistic_id"], :name => "index_comparative_facts_on_statistic_id"
  add_index "comparative_facts", ["view_id"], :name => "index_comparative_facts_on_view_id"

  create_table "contributors_sources", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "source_id"
  end

  add_index "contributors_sources", ["source_id"], :name => "index_contributors_sources_on_source_id"
  add_index "contributors_sources", ["user_id"], :name => "index_contributors_sources_on_user_id"

  create_table "contributors_views", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "view_id"
  end

  add_index "contributors_views", ["user_id"], :name => "index_contributors_views_on_user_id"
  add_index "contributors_views", ["view_id"], :name => "index_contributors_views_on_view_id"

  create_table "count_facts", force: true do |t|
    t.integer  "year"
    t.string   "direction"
    t.integer  "count_variable_id"
    t.integer  "transit_mode_id"
    t.integer  "sector_id"
    t.integer  "transit_agency_id"
    t.integer  "hour"
    t.integer  "in_station_id"
    t.integer  "out_station_id"
    t.integer  "transit_route_id"
    t.integer  "location_id"
    t.float    "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "view_id"
  end

  add_index "count_facts", ["count_variable_id"], :name => "index_count_facts_on_count_variable_id"
  add_index "count_facts", ["location_id"], :name => "index_count_facts_on_location_id"
  add_index "count_facts", ["sector_id"], :name => "index_count_facts_on_sector_id"
  add_index "count_facts", ["transit_agency_id"], :name => "index_count_facts_on_transit_agency_id"
  add_index "count_facts", ["transit_mode_id"], :name => "index_count_facts_on_transit_mode_id"
  add_index "count_facts", ["transit_route_id"], :name => "index_count_facts_on_transit_route_id"
  add_index "count_facts", ["view_id"], :name => "index_count_facts_on_view_id"

  create_table "count_variables", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "count_variables_transit_modes", id: false, force: true do |t|
    t.integer "count_variable_id"
    t.integer "transit_mode_id"
  end

  add_index "count_variables_transit_modes", ["count_variable_id"], :name => "index_count_variables_transit_modes_on_count_variable_id"
  add_index "count_variables_transit_modes", ["transit_mode_id"], :name => "index_count_variables_transit_modes_on_transit_mode_id"

  create_table "custom_breaks_color_schemes", force: true do |t|
    t.string   "color",        null: false
    t.float    "min_value"
    t.float    "max_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "symbology_id"
    t.string   "label"
  end

  add_index "custom_breaks_color_schemes", ["symbology_id"], :name => "index_custom_breaks_color_schemes_on_symbology_id"

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",         default: 0, null: false
    t.integer  "attempts",         default: 0, null: false
    t.text     "handler",                      null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "progress_stage"
    t.integer  "progress_current", default: 0
    t.integer  "progress_max",     default: 0
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "demographic_facts", force: true do |t|
    t.integer  "view_id"
    t.integer  "area_id"
    t.integer  "year"
    t.integer  "statistic_id"
    t.float    "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "demographic_facts", ["area_id"], :name => "index_demographic_facts_on_area_id"
  add_index "demographic_facts", ["statistic_id"], :name => "index_demographic_facts_on_statistic_id"
  add_index "demographic_facts", ["view_id"], :name => "index_demographic_facts_on_view_id"

  create_table "geometric_breaks_color_schemes", force: true do |t|
    t.string   "start_color",  null: false
    t.string   "end_color",    null: false
    t.float    "gap_value",    null: false
    t.float    "multiplier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "symbology_id"
  end

  add_index "geometric_breaks_color_schemes", ["symbology_id"], :name => "index_geometric_breaks_color_schemes_on_symbology_id"

  create_table "infrastructures", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "infrastructures", ["name"], :name => "index_infrastructures_on_name"

  create_table "librarians_sources", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "source_id"
  end

  add_index "librarians_sources", ["source_id"], :name => "index_librarians_sources_on_source_id"
  add_index "librarians_sources", ["user_id"], :name => "index_librarians_sources_on_user_id"

  create_table "librarians_views", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "view_id"
  end

  add_index "librarians_views", ["user_id"], :name => "index_librarians_views_on_user_id"
  add_index "librarians_views", ["view_id"], :name => "index_librarians_views_on_view_id"

  create_table "link_speed_facts", force: true do |t|
    t.integer  "view_id"
    t.integer  "link_id"
    t.integer  "year",             limit: 2
    t.integer  "month",            limit: 2
    t.integer  "day_of_week",      limit: 2, default: 0
    t.integer  "hour",             limit: 2
    t.integer  "road_id"
    t.string   "direction"
    t.integer  "area_id"
    t.integer  "base_geometry_id"
    t.integer  "speed",            limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "link_speed_facts", ["area_id"], :name => "index_link_speed_facts_on_area_id"
  add_index "link_speed_facts", ["base_geometry_id"], :name => "index_link_speed_facts_on_base_geometry_id"
  add_index "link_speed_facts", ["day_of_week"], :name => "index_link_speed_facts_on_day_of_week"
  add_index "link_speed_facts", ["hour"], :name => "index_link_speed_facts_on_hour"
  add_index "link_speed_facts", ["link_id"], :name => "index_link_speed_facts_on_link_id"
  add_index "link_speed_facts", ["month"], :name => "index_link_speed_facts_on_month"
  add_index "link_speed_facts", ["road_id"], :name => "index_link_speed_facts_on_road_id"
  add_index "link_speed_facts", ["view_id"], :name => "index_link_speed_facts_on_view_id"
  add_index "link_speed_facts", ["year"], :name => "index_link_speed_facts_on_year"

  create_table "links", force: true do |t|
    t.integer  "area_id"
    t.string   "direction"
    t.integer  "road_id"
    t.integer  "speed_limit"
    t.integer  "length"
    t.integer  "base_geometry_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "link_id",          limit: 8
  end

  add_index "links", ["area_id"], :name => "index_links_on_area_id"
  add_index "links", ["base_geometry_id"], :name => "index_links_on_base_geometry_id"
  add_index "links", ["road_id"], :name => "index_links_on_road_id"

  create_table "locations", force: true do |t|
    t.string   "name"
    t.integer  "sector_id"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "surface_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["sector_id"], :name => "index_locations_on_sector_id"

  create_table "map_layers", force: true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "name"
    t.string   "category"
    t.string   "layer_type"
    t.string   "geometry_type"
    t.string   "reference_column"
    t.string   "label_column"
    t.boolean  "visibility",           default: true
    t.boolean  "label_visibility",     default: false
    t.string   "version"
    t.string   "style"
    t.string   "highlight_style"
    t.text     "attribution"
    t.text     "predefined_symbology"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mpos", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "natural_breaks_color_schemes", force: true do |t|
    t.string   "start_color",  null: false
    t.string   "end_color",    null: false
    t.integer  "class_count",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "symbology_id"
  end

  add_index "natural_breaks_color_schemes", ["symbology_id"], :name => "index_natural_breaks_color_schemes_on_symbology_id"

  create_table "number_formatters", force: true do |t|
    t.string   "format_type", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "options"
  end

  create_table "performance_measures_facts", force: true do |t|
    t.integer  "view_id"
    t.integer  "area_id"
    t.integer  "period",                 limit: 2, default: 0
    t.integer  "functional_class",       limit: 2, default: 0
    t.integer  "vehicle_miles_traveled"
    t.integer  "vehicle_hours_traveled"
    t.float    "avg_speed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "performance_measures_facts", ["area_id"], :name => "index_performance_measures_facts_on_area_id"
  add_index "performance_measures_facts", ["functional_class"], :name => "index_performance_measures_facts_on_functional_class"
  add_index "performance_measures_facts", ["period"], :name => "index_performance_measures_facts_on_period"
  add_index "performance_measures_facts", ["view_id"], :name => "index_performance_measures_facts_on_view_id"

  create_table "plan_portions", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plan_portions", ["name"], :name => "index_plan_portions_on_name"

  create_table "project_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "project_categories", ["name"], :name => "index_project_categories_on_name"

  create_table "ptypes", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ptypes", ["name"], :name => "index_ptypes_on_name"

  create_table "quantile_breaks_color_schemes", force: true do |t|
    t.string   "start_color",  null: false
    t.string   "end_color",    null: false
    t.integer  "class_count",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "symbology_id"
  end

  add_index "quantile_breaks_color_schemes", ["symbology_id"], :name => "index_quantile_breaks_color_schemes_on_symbology_id"

  create_table "roads", force: true do |t|
    t.string   "name"
    t.string   "number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "direction"
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "rtp_projects", force: true do |t|
    t.text     "geography"
    t.integer  "plan_portion_id"
    t.integer  "infrastructure_id"
    t.string   "rtp_id"
    t.integer  "project_category_id"
    t.text     "description"
    t.integer  "sponsor_id"
    t.integer  "ptype_id"
    t.integer  "year"
    t.float    "estimated_cost"
    t.integer  "county_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "view_id"
  end

  add_index "rtp_projects", ["county_id"], :name => "index_rtp_projects_on_county_id"
  add_index "rtp_projects", ["infrastructure_id"], :name => "index_rtp_projects_on_infrastructure_id"
  add_index "rtp_projects", ["plan_portion_id"], :name => "index_rtp_projects_on_plan_portion_id"
  add_index "rtp_projects", ["project_category_id"], :name => "index_rtp_projects_on_project_category_id"
  add_index "rtp_projects", ["ptype_id"], :name => "index_rtp_projects_on_ptype_id"
  add_index "rtp_projects", ["rtp_id"], :name => "index_rtp_projects_on_rtp_id"
  add_index "rtp_projects", ["sponsor_id"], :name => "index_rtp_projects_on_sponsor_id"
  add_index "rtp_projects", ["view_id"], :name => "index_rtp_projects_on_view_id"

  create_table "sectors", force: true do |t|
    t.string   "name"
    t.integer  "counts"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "group"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id", :unique => true
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shapefile_exports", force: true do |t|
    t.integer  "view_id"
    t.integer  "delayed_job_id"
    t.text     "file_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "status"
    t.text     "message"
    t.integer  "user_id"
    t.integer  "tmp_shapefile_id"
  end

  add_index "shapefile_exports", ["delayed_job_id"], :name => "index_shapefile_exports_on_delayed_job_id"
  add_index "shapefile_exports", ["tmp_shapefile_id"], :name => "index_shapefile_exports_on_tmp_shapefile_id"
  add_index "shapefile_exports", ["user_id"], :name => "index_shapefile_exports_on_user_id"
  add_index "shapefile_exports", ["view_id"], :name => "index_shapefile_exports_on_view_id"

  create_table "simple_population_facts", force: true do |t|
    t.string   "area_name"
    t.float    "population"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "simple_year_pop_facts", force: true do |t|
    t.string   "area_name"
    t.float    "pop_2000"
    t.float    "pop_2005"
    t.float    "pop_2010"
    t.float    "pop_2015"
    t.float    "pop_2020"
    t.float    "pop_2025"
    t.float    "pop_2030"
    t.float    "pop_2035"
    t.float    "pop_2040"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "snapshots", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.integer  "view_id"
    t.integer  "app"
    t.integer  "area_id"
    t.integer  "range_low"
    t.integer  "range_high"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "filters"
    t.text     "table_settings"
    t.text     "map_settings"
    t.boolean  "published",      default: false
  end

  create_table "sources", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "current_version"
    t.datetime "data_starts_at"
    t.datetime "data_ends_at"
    t.string   "origin_url"
    t.integer  "user_id"
    t.datetime "rows_updated_at"
    t.integer  "rows_updated_by_id"
    t.string   "topic_area"
    t.string   "source_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "default_data_model"
    t.integer  "agency_id"
    t.text     "disclaimer"
    t.text     "short_description"
  end

  create_table "speed_fact_tmc_version_mappings", force: true do |t|
    t.integer  "data_year"
    t.integer  "tmc_year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "speed_facts", force: true do |t|
    t.integer  "tmc_id"
    t.integer  "year",             limit: 2
    t.integer  "month",            limit: 2
    t.integer  "day_of_week",      limit: 2, default: 0
    t.integer  "hour",             limit: 2
    t.integer  "road_id"
    t.integer  "vehicle_class",              default: 0
    t.string   "direction"
    t.integer  "area_id"
    t.integer  "speed",            limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "view_id"
    t.integer  "base_geometry_id"
  end

  add_index "speed_facts", ["area_id"], :name => "index_speed_facts_on_area_id"
  add_index "speed_facts", ["day_of_week"], :name => "index_speed_facts_on_day_of_week"
  add_index "speed_facts", ["hour"], :name => "index_speed_facts_on_hour"
  add_index "speed_facts", ["month"], :name => "index_speed_facts_on_month"
  add_index "speed_facts", ["road_id"], :name => "index_speed_facts_on_road_id"
  add_index "speed_facts", ["tmc_id"], :name => "index_speed_facts_on_tmc_id"
  add_index "speed_facts", ["vehicle_class"], :name => "index_speed_facts_on_vehicle_class"
  add_index "speed_facts", ["view_id"], :name => "index_speed_facts_on_view_id"
  add_index "speed_facts", ["year"], :name => "index_speed_facts_on_year"

  create_table "sponsors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sponsors", ["name"], :name => "index_sponsors_on_name"

  create_table "statistics", force: true do |t|
    t.string   "name"
    t.integer  "scale"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "symbologies", force: true do |t|
    t.string   "subject",                             null: false
    t.string   "default_column_index"
    t.boolean  "show_legend",          default: true
    t.string   "symbology_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number_formatter_id"
    t.integer  "view_id"
    t.boolean  "is_default"
    t.integer  "base_symbology_id"
  end

  add_index "symbologies", ["number_formatter_id"], :name => "index_symbologies_on_number_formatter_id"
  add_index "symbologies", ["view_id"], :name => "index_symbologies_on_view_id"

  create_table "tip_projects", force: true do |t|
    t.text     "geography"
    t.integer  "view_id"
    t.string   "tip_id"
    t.integer  "ptype_id"
    t.float    "cost"
    t.integer  "mpo_id"
    t.integer  "county_id"
    t.integer  "sponsor_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tip_projects", ["county_id"], :name => "index_tip_projects_on_county_id"
  add_index "tip_projects", ["mpo_id"], :name => "index_tip_projects_on_mpo_id"
  add_index "tip_projects", ["ptype_id"], :name => "index_tip_projects_on_ptype_id"
  add_index "tip_projects", ["sponsor_id"], :name => "index_tip_projects_on_sponsor_id"
  add_index "tip_projects", ["tip_id"], :name => "index_tip_projects_on_tip_id"
  add_index "tip_projects", ["view_id"], :name => "index_tip_projects_on_view_id"

  create_table "tmcs", force: true do |t|
    t.string   "name"
    t.integer  "base_geometry_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "year"
    t.integer  "index"
  end

  add_index "tmcs", ["base_geometry_id"], :name => "index_tmcs_on_base_geometry_id"
  add_index "tmcs", ["index"], :name => "index_tmcs_on_index", :unique => true

  create_table "tmp_shapefiles", force: true do |t|
    t.binary   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transit_agencies", force: true do |t|
    t.string   "name"
    t.string   "contact"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transit_modes", force: true do |t|
    t.string   "name"
    t.string   "type"
    t.string   "group"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transit_routes", force: true do |t|
    t.string   "name"
    t.integer  "transit_agency_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transit_routes", ["transit_agency_id"], :name => "index_transit_routes_on_transit_agency_id"

  create_table "transit_stations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "unique_value_color_schemes", force: true do |t|
    t.string   "color",        null: false
    t.string   "value",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "symbology_id"
    t.string   "label"
  end

  add_index "unique_value_color_schemes", ["symbology_id"], :name => "index_unique_value_color_schemes_on_symbology_id"

  create_table "uploads", force: true do |t|
    t.integer  "view_id"
    t.string   "filename"
    t.string   "s3_location"
    t.integer  "year"
    t.integer  "month"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "size_in_bytes"
    t.integer  "user_id"
    t.integer  "status",           default: 0
    t.integer  "delayed_job_id"
    t.integer  "source_id"
    t.integer  "to_year"
    t.string   "data_level"
    t.string   "geometry_version"
  end

  add_index "uploads", ["delayed_job_id"], :name => "index_uploads_on_delayed_job_id"
  add_index "uploads", ["source_id"], :name => "index_uploads_on_source_id"
  add_index "uploads", ["view_id"], :name => "index_uploads_on_view_id"

  create_table "upwp_projects", force: true do |t|
    t.integer  "view_id"
    t.integer  "year"
    t.string   "project_id"
    t.string   "name"
    t.integer  "project_category_id"
    t.integer  "sponsor_id"
    t.string   "agency_code"
    t.text     "description"
    t.float    "total_staff_cost"
    t.integer  "total_consultant_cost"
    t.integer  "budgeted_other_cost"
    t.text     "deliverables"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "num_contracts"
  end

  add_index "upwp_projects", ["project_category_id"], :name => "index_upwp_projects_on_project_category_id"
  add_index "upwp_projects", ["sponsor_id"], :name => "index_upwp_projects_on_sponsor_id"
  add_index "upwp_projects", ["view_id"], :name => "index_upwp_projects_on_view_id"

  create_table "upwp_related_contracts", force: true do |t|
    t.integer  "view_id"
    t.integer  "upwp_project_id"
    t.string   "contract_project_id"
    t.string   "name"
    t.integer  "program_year"
    t.integer  "actual_programmed_year"
    t.integer  "budgeted_consultant_cost"
    t.text     "detail"
    t.integer  "fhwa_carryover"
    t.integer  "fta_carryover"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "upwp_related_contracts", ["upwp_project_id"], :name => "index_upwp_related_contracts_on_upwp_project_id"
  add_index "upwp_related_contracts", ["view_id"], :name => "index_upwp_related_contracts_on_view_id"

  create_table "users", force: true do |t|
    t.string   "email",                           default: "", null: false
    t.string   "encrypted_password",              default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "display_name"
    t.text     "description"
    t.string   "phone"
    t.integer  "recent_activity_dashboard_limit", default: 3
    t.integer  "recent_activity_expanded_limit",  default: 10
    t.integer  "agency_id"
    t.integer  "snapshot_limit",                  default: 10
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

  create_table "viewers_snapshots", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "snapshot_id"
  end

  add_index "viewers_snapshots", ["snapshot_id"], :name => "index_viewers_snapshots_on_snapshot_id"
  add_index "viewers_snapshots", ["user_id"], :name => "index_viewers_snapshots_on_user_id"

  create_table "viewers_study_areas", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "study_area_id"
  end

  add_index "viewers_study_areas", ["study_area_id"], :name => "index_viewers_study_areas_on_study_area_id"
  add_index "viewers_study_areas", ["user_id"], :name => "index_viewers_study_areas_on_user_id"

  create_table "views", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "source_id"
    t.integer  "current_version"
    t.datetime "data_starts_at"
    t.datetime "data_ends_at"
    t.string   "origin_url"
    t.integer  "user_id"
    t.datetime "rows_updated_at"
    t.integer  "rows_updated_by_id"
    t.string   "topic_area"
    t.integer  "download_count"
    t.datetime "last_displayed_at"
    t.integer  "view_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "columns"
    t.text     "data_model"
    t.integer  "statistic_id"
    t.text     "column_types"
    t.text     "data_levels"
    t.string   "value_name"
    t.text     "column_labels"
    t.string   "row_name"
    t.string   "column_name"
    t.text     "spatial_level"
    t.text     "data_hierarchy"
    t.integer  "geometry_base_year"
    t.datetime "deleted_at"
    t.text     "download_instructions"
    t.text     "value_columns"
    t.text     "short_description"
  end

  create_table "views_actions", id: false, force: true do |t|
    t.integer "view_id"
    t.integer "action_id"
  end

  add_index "views_actions", ["view_id", "action_id"], :name => "index_views_actions_on_view_id_and_action_id"

  create_table "watches", force: true do |t|
    t.integer  "user_id"
    t.integer  "source_id"
    t.integer  "view_id"
    t.datetime "last_seen_at"
    t.datetime "last_triggered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
