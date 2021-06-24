## This script does following things:
##  1. find out duplicated road records: one with "\r\n" in direction, the other one without
##  2. update speed_fact road reference as the correct road records without "\r\n" in direction
##  3. update speed_fact direction by removing "\r\n"
##  4. delete duplicated road records with "\r\n" in direction
## To run: 
##  rake gateway:clean_up_roads

#  1. find out duplicated road records: one with "\r\n" in direction, the other one without
puts 'querying duplicated roads'
duplicated_roads = {}
Road.where("direction like ?", "%\r\n%").each do |r|
  valid_r = Road.where(name: r.name, number: r.number, direction: r.direction.strip).first;
  duplicated_roads[r.id] = valid_r.id if valid_r
end
puts "found #{duplicated_roads.count} duplicates"

puts 'cleaning up speed facts'
SpeedFact.transaction do
  $stdout.sync = true
  # 2. update speed_fact road reference as the correct road records without "\r\n" in direction
  duplicated_roads.each_with_index do |(old_id, new_id), index|
    SpeedFact.where(road_id: old_id).update_all(road_id: new_id)
    puts index if index % 100 == 0
    print '.'
  end
  puts
  puts 'updated duplicate roads'
end

puts 'cleaning up roads'
# 3. delete duplicated road records with "\r\n" in direction
Road.transaction do
  Road.where(id: duplicated_roads.keys).delete_all
  Road.where("direction like ?", "%\r\n%").update_all("direction=left(direction, length(direction)-2)")
end

puts 'cleaning up direction'

# 4. update speed_fact direction by stripping all but first character
SpeedFact.where("char_length(direction) > 1").update_all("direction=left(direction, 1)")

puts 'cleaned up direction'

puts 'roads and speed_facts clean up done'
