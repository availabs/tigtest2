# This seeding script is only executed when ENV['load_base_overlay'] = true
# Choose Overlays to load
#   1. Check available overlays by looking at AVAILABLE_OVERLAYS hash keys
#   2. list overlay key in ENV cmd via OVERLAYS_TO_LOAD=[]
#     e.g., OVERLAYS_TO_LOAD='uab'
# A full sample command
#   rake db:seed load_base_overlay=true OVERLAYS_TO_LOAD='uab'

require 'json'
require 'rgeo/geo_json'

# main function to load overlay from a geojson file to postgis table
def load_overlay_from_geojson(overlay_config)
  if !BaseOverlay || !BaseGeometry
    return
  end

  overlay_config = overlay_config || {};
  type = overlay_config[:type]
  file_path = overlay_config[:file_name]
  match_column = overlay_config[:match_column]

  puts "loading #{type} overlay from geojson file"
  input_file = File.read(file_path)
  features = RGeo::GeoJSON.decode(input_file, :json_parser => :json, :geo_factory => RGeo::Cartesian.factory(srid: 4326))

  features.each do |feature|
    name = feature[match_column].to_s.titleize
    base_overlay = BaseOverlay.where(name: name, overlay_type: type).first_or_create
    base_overlay.update_attributes(:properties => feature.properties.to_json)
    base_overlay.save!

    if !base_overlay.base_geometry
      base_overlay.base_geometry = BaseGeometry.new
    end
    base_overlay.base_geometry.update_attributes(:geom => feature.geometry)
    base_overlay.base_geometry.save!
  end

  puts "#{type} overlay loaded"
end

# available overlaye files to load
AVAILABLE_OVERLAYS = {
  uab: {
    file_name: File.join(Rails.root, 'public', 'data', 'NYMTC_UAB.geojson'),
    type: BaseOverlay::OVERLAY_TYPES[:uab],
    match_column: 'ADJ_BLK'
  }
}

# find overlays to load
# check AVAILABLE_OVERLAYSS{} keys for available overlay indexes to be used in seed cmd
if ENV["OVERLAYS_TO_LOAD"]
  OVERLAYS_TO_LOAD = ENV["OVERLAYS_TO_LOAD"].to_s.split(',') || []
end

# execution
OVERLAYS_TO_LOAD.each do |overlay_index|
  if !overlay_index
    next
  end

  overlay_config_data = AVAILABLE_OVERLAYS[overlay_index.strip.downcase.to_sym]
  if overlay_config_data
    load_overlay_from_geojson(overlay_config_data)
  end
end