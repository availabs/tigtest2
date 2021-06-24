data = [
  {category: :taz, version: '2005'},
  {category: :taz, version: '2010'},
  {category: :county, version: '2010'},
  {category: :census_tract, version: '2010'},
  {category: :subregion, version: '2010'},
  {category: :region, version: '2010'},
  {category: :tcc, version: '2010'},
  {category: :tmc, version: '2013'},
  {category: :tmc, version: '2014'},
  {category: :link, version: '2014'},
  {category: :hub_bound, version: '2010'},
  {category: :urban_area_boundary, version: '2010'},
  {category: :bpm_highway, version: '2010'}
]

data.each do |config|
  BaseGeometryVersion.where(config).first_or_create
end