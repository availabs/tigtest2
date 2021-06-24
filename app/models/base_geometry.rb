class BaseGeometry < ActiveRecord::Base
  has_one :area
  has_one :base_overlay
  has_one :tmc
  has_one :speed_fact

  def geom_as_json
    RGeo::GeoJSON.encode(geom) if geom
  end

  def self.geom_from_wkt(wkt)
    RGeo::Cartesian.factory(srid: 4326).parse_wkt(wkt) rescue nil
  end
end
