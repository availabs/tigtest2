#source
source = Source.find_or_create_by(name: 'TRANSCOM')
source.update_attribute(:description, "Transportation Operations Coordinating Committee")

#view
view = source.views.where(name: 'TRANSCOM Speed Data').first_or_create
attributes = {
  data_model: LinkSpeedFact,
  description: "TRANSCOM DFE Native Link Aggregated Speed Data",
  data_levels: ['Link'],
  data_hierarchy: [["link", "county", ["subregion", "region"]]],
  statistic_id: Statistic.find_or_create_by(name: 'Speed (mph)').id,
  value_name: :speed,
  row_name: :link,
  column_name: :hour
}
view.update_attributes(attributes)

[:table, :map, :view_metadata, :edit_metadata].each {|a| view.add_action(a)}

view.symbologies.delete_all
LinkSpeedFactSymbologyService.new(view).configure_symbology
