layer_configs = {}

layer_configs[:bpm_highway] = {
  layer_type: 'PBF_TILE', 
  version: '2010',
  category: "bpm_highway",
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.41ed16a9/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NYBPM_HIGHWAY_2010',
  title: 'NYBPM Highway Network',
  reference_column: 'ID',
  attribution: 'Highway network data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>',
  visibility: false,
  geometry_type: 'POLYLINE',
  style: {
    size: 1
  }.to_s,
  predefined_symbology: {
    symbology_type: 'unique_value',
    field: 'FCLSCode',
    colors: {
      'PAI' => 'rgb(0, 0, 0)',
      'PaEF' => 'rgb(0, 176, 80)',
      'PAO' => 'rgb(255, 255, 0)',
      'MiA' => 'rgb(255, 0, 0)',
      'MaC' => 'rgb(6, 66, 236)',
      'MiC' => 'rgb(0, 255, 255)',
      'R' => 'rgb(255, 153, 255)',
      'L' => 'rgb(191, 191, 191)'
    },
    labels: {
      'PAI' => 'Principal Arterial Interstate',
      'PaEF' => 'Principal Arterial/Expressway/Freeway',
      'PAO' => 'Principal Arterial Other',
      'MiA' => 'Minor Arterial',
      'MaC' => 'Major Collector',
      'MiC' => 'Minor Collector',
      'R' => 'Ramps',
      'L' => 'Local'
    }
  }.to_s
}

layer_configs.each do |key, config|
  if !MapLayer.find_by(category: config[:category], version: config[:version])
    MapLayer.create(config)
  end
end

BaseGeometryVersion.where(category: 'bpm_highway', version: '2010').first_or_create

