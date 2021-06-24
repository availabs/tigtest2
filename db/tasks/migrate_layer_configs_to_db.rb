layer_configs = {}
layer_configs[:uab] = {
  layer_type: 'PBF_TILE', 
  version: '2010',
  category: "urban_area_boundary",
  url: 'https://a.tiles.mapbox.com/v4/xudongcamsys.93022b4e/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IlhHVkZmaW8ifQ.hAMX5hSW-QnTeRCMAy9A8Q',
  name: 'NYMTC_UAB',
  reference_column: 'ADJ_BLK',
  title: 'Urban Area Boundary',
  attribution: 'Urban Area Boundary map data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>',
  visibility: false,
  style: {
    size: 1
  }.to_s,
  geometry_type: 'POLYGON',
  predefined_symbology: {
    symbology_type: 'unique_value',
    field: 'ADJ_BLK',
    colors: {
      'A' => 'rgba(255, 0, 0, 0.5)',
      'C' => 'rgba(0, 255, 0, 0.5)',
      'R' => 'rgba(0, 0, 255, 0.5)',
      'U' => 'rgba(255, 255, 0, 0.5)'
    },
    labels: {
      'A' => 'NYMTC Adjusted Urban',
      'C' => 'Census Cluster',
      'R' => 'Census Rural',
      'U' => 'Census Urban'
    }
  }.to_s
}

layer_configs[:census_tract] = {
  layer_type: 'PBF_TILE', 
  version: '2010',
  category: "census_tract",
  url: 'https://a.tiles.mapbox.com/v4/xudongcamsys.0c4d3daa/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IlhHVkZmaW8ifQ.hAMX5hSW-QnTeRCMAy9A8Q',
  name: 'NYMTC_CT',
  reference_column: 'DISP_NAME',
  title: 'Census Tract',
  geometry_type: 'POLYGON',
  attribution: 'Census tract map data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>',
  style: {
    size: 1,
    outline: {
      color: "transparent",
      size: 0.1
    }
  }.to_s
}

layer_configs[:tcc] = {
  layer_type: 'PBF_TILE', 
  version: '2010',
  category: "tcc",
  url: 'https://a.tiles.mapbox.com/v4/xudongcamsys.e6437adb/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IlhHVkZmaW8ifQ.hAMX5hSW-QnTeRCMAy9A8Q',
  name: 'NYMTC_TCC',
  reference_column: 'TCC',
  title: 'TCC',
  geometry_type: 'POLYGON',
  attribution: 'TCC map data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>',
  style: {
    size: 1
  }.to_s
}

layer_configs[:taz] = {
  layer_type: 'PBF_TILE', 
  version: '2005',
  category: "taz",
  url: 'https://a.tiles.mapbox.com/v4/xudongcamsys.bd3704b0/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IlhHVkZmaW8ifQ.hAMX5hSW-QnTeRCMAy9A8Q',
  name: 'NYMTC_TAZ',
  reference_column: 'TAZ_ID',
  title: 'NYBPM TAZs',
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

layer_configs[:county] = {
  layer_type: 'PBF_TILE', 
  version: '2010',
  category: "county",
  url: 'https://a.tiles.mapbox.com/v4/xudongcamsys.59fe3b7a/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IlhHVkZmaW8ifQ.hAMX5hSW-QnTeRCMAy9A8Q',
  name: 'NYMTC_County',
  reference_column: 'NAME',
  title: 'Counties',
  label_visibility: true,
  label_column: 'NAME',
  geometry_type: 'POLYGON',
  attribution: 'County map data &copy; <a href="http://census.gov/">US Census Bureau</a>',
  style: {
    size: 1
  }.to_s
}

layer_configs[:subregion] = {
  layer_type: 'PBF_TILE', 
  version: '2010',
  category: "subregion",
  url: 'https://a.tiles.mapbox.com/v4/xudongcamsys.d6d85538/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IlhHVkZmaW8ifQ.hAMX5hSW-QnTeRCMAy9A8Q',
  name: 'NYMTC_Subregion',
  reference_column: 'NAME',
  title: 'NYMTC Subregion',
  geometry_type: 'POLYGON',
  attribution: 'Subregion map data &copy; <a href="http://census.gov/">US Census Bureau</a>',
  style: {
    size: 1
  }.to_s
}

layer_configs[:tmc] = {
  layer_type: 'PBF_TILE', 
  version: '2013',
  category: "tmc",
  url: 'https://a.tiles.mapbox.com/v4/xudongcamsys.39367dd1/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IlhHVkZmaW8ifQ.hAMX5hSW-QnTeRCMAy9A8Q',
  name: 'NHS_TMC_2013',
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

layer_configs[:hub_bound] = {
  layer_type: 'Geojson',
  version: '2010', 
  category: 'hub_bound',
  url: '/data/hub_bound.geojson',
  name: 'Hub Boundary',
  title: 'Hub Boundary',
  attribution: 'Hub Boundary map data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>',
  geometry_type: 'POLYLINE',
  predefined_symbology: {
    colors: {
      'Boundary' => 'black'
    },
    labels: {
      'Boundary' => 'Boundary Line'
    }
  }.to_s,
  style: {
    fill: false,
    color: 'black',
    clickable: false,
    weight: 1.5,
    dashArray: '10 5'
  }.to_s
}

layer_configs.each do |key, config|
  if !MapLayer.find_by_category(config[:category])
    MapLayer.create(config)
  end
end

