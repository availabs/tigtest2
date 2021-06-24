layer_configs = {}

layer_configs[:link] = {
  layer_type: 'PBF_TILE', 
  version: '2014',
  category: "link",
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.3f1b708d/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'transcom_link',
  reference_column: 'LINKID',
  title: 'LINK',
  geometry_type: 'POLYLINE',
  attribution: 'LINK map data &copy; TRANSCOM',
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

