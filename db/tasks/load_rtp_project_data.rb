# Load RTP Project data from shapefiles

source_attributes = {
  description: 'Data related to projects in the Regional Transportation Plan.',
  :origin_url => "http://nymtc.org/"
}

puts 'Set Source'
source = Source.find_or_create_by(name: 'RTP Project Data')
source.update_attributes(source_attributes)

view_attributes = {
  description: '2040 RTP Project List',
  data_model: RtpProject,
  columns: ['rtp_id', 'description', 'year', 'estimated_cost', 'ptype', 'plan_portion', 'sponsor', 'county'],
  column_types: ['', '', '', 'millions'],
  data_levels: ['Project']
}

view_actions = [:table, :map, :view_metadata, :edit_metadata]

puts 'Set View'
view = source.views.where(name: '2040 RTP Projects').first_or_create
view.update_attributes(view_attributes)
view_actions.each {|a| view.add_action(a)}

RtpProjectSymbologyService.new(view).configure_symbology

dir = 'rtp_2040_shp'
files = ['rtp_points_2040_wgs84.shp', 'rtp_lines_2040_wgs84.shp', 'rtp_polygons_2040_wgs84.shp']

RtpProject.where(view: view).delete_all
files.each do |file|
  RtpProject.loadShp(File.join(Rails.root, 'db', dir, file), view)
end
