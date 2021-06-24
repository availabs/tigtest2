# 1.3.4 version of Partitioned appears to be slightly incompatible
# with Rails (AR?) 4
# debugged and generated the two monkey patches required below

require 'gateway_monkey_patch_postgres.rb'
require 'gateway_reader.rb'

SpeedFact.create_infrastructure
partitions = [2013]
(4..12).each do |month|
  partitions << [2013, month]
end
print partitions
puts
SpeedFact.create_new_partition_tables(partitions)
(4..12).each do |month|
  (1..24).each do |hour|
    (1..7).each do |dow|
      rows = SpeedFact.where(year: 2013, month: month, hour: hour, day_of_week: dow)
             .select(:tmc_id, :day_of_week, :hour, :road_id, :vehicle_class, :direction,
                     :area_id, :speed, :view_id, :base_geometry_id,
                     :year, :month).all.map do |fact|
        fact.attributes.to_options
      end
      puts "Selected #{rows.size} rows for month: #{month} hour: #{hour} dow: #{dow}"
      SpeedFact.create_many(rows)
    end
  end
end

# Necessary to delete speed_facts manually in psql: "delete from only speed_facts"
