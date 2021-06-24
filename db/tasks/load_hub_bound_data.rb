# Load Hub Bound Data sets in the form of mdb files
# Assumes that mbdtools has been installed.

source_attributes = {
  description: 'Data on travel to and from the Manhattan Central Business District (CBD) both by persons and vehicles. The Hub or CBD, is defined as that portion of Manhattan lying south of 60th Street. The data are collected on a typical fall business weekday.'
}

puts 'Set Source'
source = Source.find_or_create_by(name: 'Hub Bound Travel Data')
source.update_attributes(source_attributes)

statistic = Statistic.find_or_create_by(name: 'Count')

view_attributes = {
  description: '',
  data_model: CountFact,
  columns: ['year', 'count_variable', 'count','transit_route', 'transit_mode', 'in_station', 'out_station', 'direction', 'location', 'sector', 'hour', 'transit_agency'],
  column_labels: ["Year", "Count Variable", "Count", "Route", "Mode", "In Station", "Out Station", "Direction", "Location", "Sector", "From - To", "Transit Agency"],
  column_types: ['text-right', '', 'text-right','', '', '', '', '', '', '', 'text-center', ''],
  data_levels: ['Route'],
  statistic: statistic
}
# Not sure what data_levels or statistic really should be.

view_actions = [:table, :metadata]

puts 'Set View'
view = source.views.where(name: 'Hub Bound Travel Data').first_or_create
view.update_attributes(view_attributes)
view_actions.each {|a| view.add_action(a)}

files = ['HubData2013.mdb']

files.each do |file|
  CountFact.processMdb(File.join(Rails.root, 'db', file), view)
end
