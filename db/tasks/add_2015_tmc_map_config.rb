map_layer = MapLayer.where(category: 'tmc', version: '2015').first
if !map_layer
  MapLayer.create({
    layer_type: 'PBF_TILE', 
    version: '2015',
    category: "tmc",
    url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.c7535e59/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
    name: 'tmc_2015', 
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
  map_layer.url = 'https://a.tiles.mapbox.com/v4/nymtc-gateway.c7535e59/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg'
  map_layer.name = 'tmc_2015'
  map_layer.save!
end