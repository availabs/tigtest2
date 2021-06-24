View.all.each do |view|
data_level = view.data_levels[0]
if !data_level.blank?
  data_level = case data_level.downcase
  when 'censustract'
    Area::AREA_LEVELS[:census_tract]
  when 'county'
    Area::AREA_LEVELS[:county]
  when 'taz'
    Area::AREA_LEVELS[:taz]
  end
end
  
view.update_attribute(:data_levels, [data_level])
end

puts 'finished cleaning up view data_levels'