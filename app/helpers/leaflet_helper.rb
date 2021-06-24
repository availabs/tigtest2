module LeafletHelper

  map_configs = Rails.application.config.map_configs || {}
  # Defaults
  MAPID = "map"
  SCROLL_WHEEL_ZOOM = true
  SHOW_MY_LOCATION = false
  SHOW_STREET_VIEW= false
  STREET_VIEW_URL = map_configs[:street_view_url]
  SHOW_LOCATION_SELECT = false

  SHOW_DEFAULT_ZOOM_CONTROL = false
  ZOOM_ANIMATION = true

  def LeafletMap(options)
    options_with_indifferent_access = options.with_indifferent_access

    js_dependencies = Array.new
    #js_dependencies << 'http://cdn.leafletjs.com/leaflet-0.4/leaflet.js'
    #js_dependencies << 'leafletmap.js_x'
    #js_dependencies << 'leafletmap_icons.js_x'

    render :partial => '/leaflet/leaflet', :locals => { :options => options_with_indifferent_access, :js_dependencies => js_dependencies }
  end

  # Generates the Leaflet JS code to create the map from the options hash
  # passed in via the LeafletMap helper method
  def generate_map(options)
    js = []
    # Add any icon definitions
    js << options[:icons] unless options[:icons].nil?
    # init the map with the mapid, use default if not set
    mapid = options[:mapid] ? options[:mapid] : MAPID
    show_default_zoom_control = options[:show_default_zoom_control] || SHOW_DEFAULT_ZOOM_CONTROL
    scroll_wheel_zoom = options[:scroll_wheel_zoom] || SCROLL_WHEEL_ZOOM
    show_my_location = options[:show_my_location] || SHOW_MY_LOCATION
    show_street_view = options[:show_street_view] || SHOW_STREET_VIEW
    street_view_url = options[:street_view_url] ? options[:street_view_url] : STREET_VIEW_URL
    show_location_select = options[:show_location_select] || SHOW_LOCATION_SELECT
    zoom_animation = options[:zoom_animation] || ZOOM_ANIMATION
    min_zoom = options[:min_zoom] || nil
    max_zoom = options[:max_zoom] || nil

    mapopts = {
      show_default_zoom_control: show_default_zoom_control,
      scroll_wheel_zoom: scroll_wheel_zoom,
      zoom_animation: zoom_animation,
      show_my_location: show_my_location,
      show_street_view: show_street_view,
      street_view_url: street_view_url,
      show_location_select: show_location_select,
      min_zoom: min_zoom,
      max_zoom: max_zoom,
      map_control_tooltips: {
        zoom_in: 'Zoom in',
        zoom_out: 'Zoom out',
        my_location: 'Center my location',
        display_street_view: 'Display street view',
        select_location_on_map: 'Select location on map'
      }
    }.to_json

    viewopts = (options[:view_configs] || {}).to_json
    map_base_config = (options[:map_base_config] || {}).to_json

    is_map_snapshot_config_available = !options[:map_snapshot_configs].nil?
    view_id = options[:view_configs][:id];
    
    js << "var mapSnapshotParams = {};"
    js << "if(#{is_map_snapshot_config_available}) mapSnapshotParams = #{options[:map_snapshot_configs].to_json};"
    js << "if(!#{is_map_snapshot_config_available}) mapSnapshotParams = JSON.parse(localStorage.getItem('map-snapshot-' + #{view_id}));"
    js << "var gatewayMapApp = new GatewayMapApp('#{mapid}', #{mapopts}, #{map_base_config}, #{viewopts}, mapSnapshotParams);"
    js << "gatewayMapApp.processDataOverlaysFromSnapshot();"
    js * ("\n")
  end

  def self.marker(letter)
    "http://maps.google.com/mapfiles/marker_green#{letter}.png"
  end

end