# This assumes all existing DemographicFact and SpeedFact views follow the same
# spatial_level and data_hierarchy
View.where("data_model like '%DemographicFact%'").each do |v|
  p v.name
  v.spatial_level = 'taz'
  v.data_hierarchy = [['taz', 'county', ['subregion', 'region']]]
  v.save!
end
View.where("data_model like '%SpeedFact%'").each do |v|
  p v.name
  v.spatial_level = 'tmc'
  v.data_hierarchy = [['tmc', 'county', ['subregion', 'region']]]
  v.save!
end
