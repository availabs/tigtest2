layer_configs = {}

layer_configs[:tmc] = {
  layer_type: 'PBF_TILE', 
  version: '2014',
  category: "tmc",
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.096007e1/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'tmc_2014',
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
}

layer_configs.each do |key, config|
  if !MapLayer.find_by(category: config[:category], version: config[:version])
    MapLayer.create(config)
  end
end

