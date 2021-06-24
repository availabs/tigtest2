require 'json'
require 'rgeo/geo_json'

# main function to load TMC from a geojson file to postgis table
def load_tmc_from_geojson(config)
  if !Tmc || !BaseGeometry
    return
  end

  config = config || {};
  file_path = config[:file_name]
  match_column = config[:match_column]
  year = config[:year]

  puts "loading TMC from geojson file"
  input_file = File.read(file_path)
  features = RGeo::GeoJSON.decode(input_file, :json_parser => :json, :geo_factory => RGeo::Cartesian.factory(srid: 4326))

  features.each do |feature|
    name = feature[match_column].to_s
    tmc = Tmc.where(name: name, year: year).first_or_create

    if !tmc.base_geometry
      tmc.base_geometry = BaseGeometry.new
    end
    tmc.base_geometry.update_attributes(:geom => feature.geometry)
    tmc.base_geometry.save!
  end

  puts "TMC loaded"
end

# configuration
tmc_config = {
  file_name: File.join(Rails.root, 'public', 'data', "#{ENV['file']}.geojson"),
  year: ENV['year'],
  match_column: 'TMC'
}


# execution
load_tmc_from_geojson(tmc_config)
