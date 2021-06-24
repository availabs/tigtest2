version = '2012'
#seed 201 TAZ MapBox URL to MapLayers
if MapLayer.where(category: :taz, version: version).empty?
  config = {
    layer_type: 'PBF_TILE', 
    version: version,
    category: "taz",
    url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.0c163d91/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
    name: 'NYBPM_TAZ_2012',
    reference_column: 'TAZ_ID',
    title: 'NYBPM 2012 TAZs',
    geometry_type: 'POLYGON',
    attribution: 'TAZ map data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>',
    style: {
      size: 1,
      outline: {
        color: "transparent",
        size: 0.1
      }
    }.to_s
  }

  MapLayer.create(config)
end

# seed 2012 TAZ area geometries
require 'json'
require 'rgeo/geo_json'

# remove existing 2012 TAZ areas and associated view data
puts "deleting"
DemographicFact.joins(:area).where(areas: {type: :taz, year: 2012}).delete_all
Area.where(type: :taz, year: 2012).delete_all
puts "done deleting"

# main function to load geometries from a geojson file to postgis table
def load_geom_from_geojson(geom_config)
  if !BaseGeometry
    return
  end

  geom_config = geom_config || {};
  file_path = geom_config[:file_name]
  match_column = geom_config[:match_column]
  match_county_column = geom_config[:match_county_column]
  is_titleize_name = geom_config[:titleize_name] rescue nil

  puts "loading file"

  input_file = File.read(file_path)
  factory = RGeo::Cartesian.factory(srid: 4326)
  features = RGeo::GeoJSON.decode(input_file, :json_parser => :json, :geo_factory => factory)

  puts "processing features"
  features.each do |feature|
    name = feature[match_column].to_s
    next if name.blank?
    area = Area.where(name: name, type: :taz, year: 2012).first_or_create

    # enclosing relation
    county_name = feature[match_county_column].to_s
    county = Area.where(name: county_name, type: :county).first
    area.enclosing_areas << county if county

    if !area.base_geometry
      area.base_geometry = BaseGeometry.new
    end
    area.base_geometry.update_attributes(:geom => feature.geometry)
    area.base_geometry.save!
  end
  puts "updating BaseGeometryVersion"
  bgv_convig = {
    category: "taz",
    version: 2012 
  }

  BaseGeometryVersion.create(bgv_convig)
end


taz_config = {
  file_name: File.join(Rails.root, 'public', 'data', 'NYBPM_TAZ_2012.geojson'),
  match_column: 'TAZ_ID',
  match_county_column: 'COUNTY'
}

load_geom_from_geojson(taz_config)
