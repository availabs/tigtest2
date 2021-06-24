# This seeding script is only executed when ENV['load_area_geometry'] = true
#   Please make sure Areas table already has the area associated with the data source file to load
#   e.g., if you want to load county geometries, then Areas table should have county area data
# Choose Geoms to load
#   1. Check available geoms by looking at AVAILABLE_GEOMS hash keys
#   2. list geom key in ENV cmd via GEOMS_TO_LOAD=[]
#     e.g., GEOMS_TO_LOAD='county,census_tract'
# A full sample command
#   during initial seeding:
#     rake db:seed load_area_geometry=true GEOMS_TO_LOAD='county,census_tract'
#   or update later:
#     rake gateway:load_area_geometry GEOMS_TO_LOAD='county,census_tract'

require 'json'
require 'rgeo/geo_json'

# main function to load geometries from a geojson file to postgis table
def load_geom_from_geojson(geom_config)
  if !BaseGeometry
    return
  end

  geom_config = geom_config || {};
  type = geom_config[:type]
  file_path = geom_config[:file_name]
  match_column = geom_config[:match_column]
  is_titleize_name = geom_config[:titleize_name] rescue nil

  puts "loading #{type} geometries from geojson file"
  input_file = File.read(file_path)
  features = RGeo::GeoJSON.decode(input_file, :json_parser => :json, :geo_factory => RGeo::Cartesian.factory(srid: 4326))

  features.each do |feature|
    name = feature[match_column].to_s
    next if name.blank?
    name = name.titleize if is_titleize_name
    area = Area.where("lower(name) = ? and lower(type) = ?", name.downcase, type.downcase).first_or_create

    if !area.base_geometry
      area.base_geometry = BaseGeometry.new
    end
    area.base_geometry.update_attributes(:geom => feature.geometry)
    area.base_geometry.save!
  end

  puts "#{type} geometry loaded"
end

# available geometry files to load
AVAILABLE_GEOMS = {
  region: {
    file_name: File.join(Rails.root, 'public', 'data', 'NYMTC_Region.geojson'),
    type: Area::AREA_LEVELS[:region],
    match_column: 'NAME'
  },
  subregion: {
    file_name: File.join(Rails.root, 'public', 'data', 'NYMTC_Subregion.geojson'),
    type: Area::AREA_LEVELS[:subregion],
    match_column: 'NAME',
    titleize_name: true
  },
  tcc: {
    file_name: File.join(Rails.root, 'public', 'data', 'NYMTC_TCC.geojson'),
    type: Area::AREA_LEVELS[:tcc],
    match_column: 'TCC',
    titleize_name: true
  },
  county: {
    file_name: File.join(Rails.root, 'public', 'data', 'NYMTC_County.geojson'),
    type: Area::AREA_LEVELS[:county],
    match_column: 'NAME',
    titleize_name: true
  },
  census_tract: {
    file_name: File.join(Rails.root, 'public', 'data', 'NYMTC_CT.geojson'),
    type: Area::AREA_LEVELS[:census_tract],
    match_column: 'DISP_NAME',
    titleize_name: true
  },
  taz: {
    file_name: File.join(Rails.root, 'public', 'data', 'NYMTC_TAZ.geojson'),
    type: Area::AREA_LEVELS[:taz],
    match_column: 'TAZ_ID',
    titleize_name: true
  }
}

# find geoms to load
# check AVAILABLE_GEOMS{} keys for available geom indexes to be used in seed cmd
if ENV["GEOMS_TO_LOAD"]
  GEOMS_TO_LOAD = ENV["GEOMS_TO_LOAD"].to_s.split(',') || []
end

# execution
GEOMS_TO_LOAD.each do |geom_index|
  if !geom_index
    next
  end

  geom_config_data = AVAILABLE_GEOMS[geom_index.strip.downcase.to_sym]
  if geom_config_data
    load_geom_from_geojson(geom_config_data)
  end
end