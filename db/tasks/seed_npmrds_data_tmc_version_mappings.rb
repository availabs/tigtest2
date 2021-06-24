mappings = [
  {
    data_year: 2013,
    tmc_year: 2013
  },
  {
    data_year: 2014,
    tmc_year: 2014
  },
  {
    data_year: 2015,
    tmc_year: 2015
  },
  {
    data_year: 2016,
    tmc_year: 2016
  },
  {
    data_year: 2017,
    tmc_year: 2016
  }
]

mappings.each do |m|
  SpeedFactTmcVersionMapping.where(m).first_or_create
end