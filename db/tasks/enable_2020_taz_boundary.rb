# Sample Usage:
#   RAILS_ENV=test bundle exec rake gateway:enable_2020_taz_boundary
#
# To create the GeoJSON from an ESRI Shapefile
#   ogr2ogr -t_srs EPSG:4326 -f GeoJSON /vsistdout/ 2021_TAZOutputs_Final -select 'TAZ2012' | jq -c '.features[]' | sed 's/TAZ2012/id/g' > 2021_TAZOutputs_Final.geojsonl
#
# To create the MBTiles, use https://github.com/mapbox/tippecanoe
#   tippecanoe --force -o 2021_tazoutputs_final.mbtiles 2021_TAZOutputs_Final.geojsonl

TAZ_VERSION = '2020'

TAZ_CONFIG = {
  file_name: File.join(Rails.root, 'public', 'data', "2021_TAZOutputs_Final.geojson"),
  match_column: 'TAZ2012',
  match_county_column: 'County_Nam'
}

BASE_GEOMETRY_VERSION_CONFIG = {
  category: "taz",
  version: TAZ_VERSION
}

# seed TAZ MapBox URL to MapLayers
if MapLayer.where(category: :taz, version: TAZ_VERSION).empty?
  config = {
    layer_type: 'PBF_TILE',
    version: TAZ_VERSION,
    category: "taz",
    url: 'https://tigtest2.nymtc.org/tiles/data/nymtc_2020_taz/{z}/{x}/{y}.pbf',#'https://a.tiles.mapbox.com/v4/nymtc-gateway.0c163d91/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
    name: "nymtc_taz_#{TAZ_VERSION}ndjson",
    reference_column: 'name',
    title: "NYBPM #{TAZ_VERSION} TAZs",
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

# seed TAZ_VERSION TAZ area geometries
# require 'json'
# require 'rgeo/geo_json'

# def pre_load_cleanup()
#   # remove existing TAZ_VERSION TAZ areas and associated view data
#   puts "deleting"
#   DemographicFact.joins(:area).where(areas: {type: :taz, year: TAZ_VERSION}).delete_all
#   Area.where(type: :taz, year: TAZ_VERSION).delete_all
#   puts "done deleting"
# end

# # main function to load geometries from a geojson file to postgis table
# def load_geom_from_geojson(geom_config)
#   if !BaseGeometry
#     return
#   end

#   file_path = geom_config[:file_name]
#   match_column = geom_config[:match_column]
#   match_county_column = geom_config[:match_county_column]
#   is_titleize_name = geom_config[:titleize_name] rescue nil

#   puts "loading file"

#   input_file = File.read(file_path)
#   factory = RGeo::Cartesian.factory(srid: 4326)
#   features = RGeo::GeoJSON.decode(input_file, :json_parser => :json, :geo_factory => factory)

#   puts "processing features"
#   features.each do |feature|
#     name = feature[match_column].to_s
#     next if name.blank?
#     area = Area.where(name: name, type: :taz, year: TAZ_VERSION).first_or_create

#     # enclosing relation
#     county_name = feature[match_county_column].to_s
#     county = Area.where(name: county_name, type: :county).first
#     area.enclosing_areas << county if county

#     if !area.base_geometry
#       area.base_geometry = BaseGeometry.new
#     end
#     area.base_geometry.update_attributes(:geom => feature.geometry)
#     area.base_geometry.save!
#   end
#   puts "updating BaseGeometryVersion"

#   ## find or create
#   BaseGeometryVersion.create(BASE_GEOMETRY_VERSION_CONFIG)
# end

# ActiveRecord::Base.transaction do
#   pre_load_cleanup()
#   load_geom_from_geojson(TAZ_CONFIG)
# end
