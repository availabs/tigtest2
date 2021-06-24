class Tmc < ActiveRecord::Base
  belongs_to :base_geometry
  belongs_to :road
  belongs_to :area

  def self.geometries
    Rails.cache.fetch('tmc_geometries') do
      geometries = Hash.new
      Tmc.joins(:base_geometry)
        .select('tmcs.id, base_geometries.id as geom_id, ST_AsGeoJSON(base_geometries.geom) as geom_json')
        .find_each {|res| geometries[res.geom_id] = res.geom_json}
      
      geometries
    end
  end

  def self.data_year_to_geo_year(data_year)
    version_mapping = SpeedFactTmcVersionMapping.find_by_data_year(data_year)
    version_mapping.tmc_year if version_mapping
  end
end
