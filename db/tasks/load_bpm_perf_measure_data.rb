# Load BPM Performance Measures from Excel files

require 'performance_measures_fact.rb'

source_attributes = {
  description: 'Best Practices Model Performance Measures',
  :origin_url => "http://nymtc.org/"
}

puts 'Set Source'
source = Source.find_or_create_by(name: 'BPM Performance Measures')
source.update_attributes(source_attributes)

base_view_attributes = {
  data_model: PerformanceMeasuresFact,
  columns: ['area', 'vehicle_miles_traveled', 'vehicle_hours_traveled', 'avg_speed'],
  column_labels: ['County', 'VMT (in Thousands)', 'VHT (in Thousands)', 'Avg. Speed (Miles/Hr)'],
  column_types: ['', 'thousands', 'thousands', 'float'],
  value_columns: ['vehicle_miles_traveled', 'vehicle_hours_traveled', 'avg_speed'],
  data_levels: ['county'],
  spatial_level: 'county',
  data_hierarchy: [["county", ["subregion", "region"]]]
}

view_actions = [:table, :map, :chart, :view_metadata, :edit_metadata, :upload, :copy]

# loop over view name, file
[
  ['2010 Base', 'VMT_VHT_AvSpeed_2010B.xlsx'],
#  ['2040 Forecast', 'VMT_VHT_AvSpeed_2040F.xlsx']
].each do |name, file|
  puts "create/update view: #{name}"
  view = View.where(name: name, source: source).first_or_create
  view.update(base_view_attributes)
  view_actions.each do |action|
    view.add_action action
  end
  
  puts "load #{file}"
  
  PerformanceMeasuresFact.where(view: view).delete_all
  filename = File.join(Rails.root, 'db', file)

  # open excel file
  xlsx = Roo::Spreadsheet.open(filename)

  PerformanceMeasuresFact.processXlsx(xlsx, view)
end


