map_layer = MapLayer.where(category: 'tmc', version: '2016').first
if !map_layer
  MapLayer.create({
    layer_type: 'PBF_TILE', 
    version: '2016',
    category: "tmc",
    url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.5ae8392c/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
    name: 'tmc_2016', 
    reference_column: 'TMC',
    title: 'TMC',
    geometry_type: 'POLYLINE',
    attribution: 'TMC map data &copy; HERE',
    style: {
      size: 2
    }.to_s,
    highlight_style: {
      size: 6,
      color: 'rgba(255, 0, 255, 0.4)'
    }.to_s
  })
else
  map_layer.name = 'tmc_2016'
  map_layer.url = 'https://a.tiles.mapbox.com/v4/nymtc-gateway.5ae8392c/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg'
  map_layer.save    
end

BaseGeometryVersion.where(category: 'tmc', version: '2016').first_or_create
tmc_version = SpeedFactTmcVersionMapping.find_by(data_year: 2016)
if tmc_version
  tmc_version.update(tmc_year: 2016)
else
  SpeedFactTmcVersionMapping.create(data_year: 2016, tmc_year: 2016)
end
puts '2016 TMC version added'