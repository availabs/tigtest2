NymtcGateway::Application.configure do
  # min height of map container
  config.min_map_height = 480; # in pixels

  # list of supported base map types
  basemap_types = {
    osw: 'OpenStreetMap',
    cloudmade: 'CloudMade',
    google: 'Google', #Possible types: SATELLITE, ROADMAP, HYBRID, TERRAIN
    esri: 'Esri' # http://esri.github.io/esri-leaflet/api-reference/layers/basemap-layer.html
  }

  # default map configurations
  map_configs = {}

  map_configs[:map_bounds] = {
    xmin: 40.11,
    ymin: -74.3,
    xmax: 41.61,
    ymax: -73.7
  }

  map_configs[:min_zoom] = 7

  map_configs[:street_view_url] = '/streetview.html'
  
  # list of basemaps
  map_configs[:basemaps] = [
    {
      type: basemap_types[:google],
      name: 'Streets',
      layerName: 'ROADMAP'
    },
    {
      type: basemap_types[:google],
      name: 'Topographic',
      layerName: 'TERRAIN'
    },
    {
      type: basemap_types[:google],
      name: 'Imagery',
      layerName: 'SATELLITE'
    }
  ]
  map_configs[:default_basemap] = 'Streets'

  map_configs[:default_break_count] = 8
  
  config.map_configs = map_configs
end
