old = 'Vehicles (Bus+Auto+Taxi+Trucks+Commercial Vans)'
new = 'Vehicles (Auto+Taxi+Trucks+Comm. Vans)'

puts "rename #{old}\nto #{new}"
veh_mode = TransitMode.where(TransitMode.arel_table[:name].matches("%Vehicles%")).first

unless veh_mode
  puts "Vehicles transit mode not found! Exiting"
  exit
end

veh_mode.update_attributes(name: new)

puts "'rename' Cars to Vehicles for Vehicles mode and 'Cars in Trains' for others"
cars = CountVariable.where(CountVariable.arel_table[:name].matches('%Cars%')).first

cars.update_attributes(name: 'Cars in Trains',
                       description: 'Number of Cars in the Trains') if cars

vehicles = CountVariable.where(name: 'Vehicles', description: 'Number of Vehicles').first_or_create

CountFact.where(count_variable: cars, transit_mode: veh_mode)
  .update_all(count_variable_id: vehicles.id)

puts "remove 'All Vehicles' facts"
var = CountVariable.find_by(name: "All Vehicles")
if var
  CountFact.delete_all(count_variable: var)
  var.delete
end

puts "change column_type for Hour to text-center"
view = View.find_by(name: "Hub Bound Travel Data")
index = view.columns.find_index("hour")
view.column_types[index] = "text-center"

puts "move count_variable and count to front"
if view.columns[0] != 'count_variable'
  view.columns = view.columns.rotate(-2)
  view.column_labels = view.column_labels.rotate(-2)
  view.column_types = view.column_types.rotate(-2)
end

view.save!
