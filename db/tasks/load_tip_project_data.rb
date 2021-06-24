# Load TIP Project data from shapefiles

source_attributes = {
  description: 'Data related to projects in the Transportation Improvement Program.',
  :origin_url => "http://nymtc.org/"
}

puts 'Set Source'
source = Source.find_or_create_by(name: 'TIP Project Data')
source.update_attributes(source_attributes)

view_attributes = {
  description: 'TIP Project List',
  data_model: TipProject,
  columns: ['tip_id', 'ptype', 'cost', 'mpo', 'county', 'sponsor', 'description'],
  column_labels: ['TIP ID', 'Project Type', 'Cost', 'MPO Name', 'County', 'Agency', 'Description', ],
  column_types: ['', '', 'millions'],
  data_levels: ['Project']
}

view_actions = [:table, :map, :view_metadata, :edit_metadata]

puts 'Set View'
view = source.views.where(name: ENV['name'] || 'TIP Projects').first_or_create
view.update_attributes(view_attributes)
view_actions.each {|a| view.add_action(a)}

TipProjectSymbologyService.new(view).configure_symbology(subject: 'TIP Projects')

dir = 'tip_2014_shp'
files = Dir[File.join(Rails.root, 'db', dir)+'/*.shp']

# Rename Its Ptype to ITS if necessary
Ptype.where(name: 'Its').update_all(name: 'ITS')

TipProject.where(view: view).delete_all
files.each do |file|
  TipProject.loadShp(file, view)
end
