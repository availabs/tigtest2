View.where("spatial_level like '%taz%'").update_all(geometry_base_year: 2005) # taz
View.where("data_model like '%ComparativeFact%'").update_all(geometry_base_year: 2010) # census_tract