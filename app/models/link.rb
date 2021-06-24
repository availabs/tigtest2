class Link < ActiveRecord::Base
  belongs_to :area
  belongs_to :road
  belongs_to :base_geometry

  attr_accessible :id

  # Directions
  DIRECTIONS = [
    ["All", ""], 
    ['Eastbound', 'E'],
    ['Westbound', 'W'],
    ['Northbound', 'N'],
    ['Southbound', 'S'], 
    ['North-East Bound', 'NE'], 
    ['South-West Bound', 'SW']
  ]
  
  def self.loadCSV(filename)
    CSV.open(filename, headers: true, return_headers: false) do |csv|
      csv.each do |row|
        link = Link.where(link_id: row['link_id']).first_or_create

        link.area = Area.find_by(name: row['County'].titleize, type: 'county')
        dir = row['Direction']
        link.direction = dir
        road_name = row['RoadName']
        link.road = Road.find_or_create_normalized(road_name, dir) unless road_name.blank?
        link.speed_limit = row['Posted Speed Limit (MPH)']
        link.length = row['Length (Meter)']

        link.save
      end
    end
  end

  def self.loadGeoJSON(filename)
    input_file = File.read(filename)
    features = RGeo::GeoJSON.decode(input_file, :json_parser => :json, :geo_factory => RGeo::Cartesian.factory(srid: 4326))
    missing_count = 0
    features.each do |feature|
      link_id = feature['LINKID'].to_i
      link = find_by(link_id: link_id)
      unless link
        Rails.logger.warn "link: #{link_id} not found, skipping"
        missing_count += 1
        next
      end
        
      unless link.base_geometry
        link.base_geometry = BaseGeometry.new
      end
      link.base_geometry.update_attributes(geom: feature.geometry)
      link.save
    end
    Rails.logger.warn "#{missing_count} missing links" if missing_count > 0
  end

  def name
    link_id.to_s
  end

  def self.geometries
    Rails.cache.fetch('transcom_link_geometries') do
      geometries = Hash.new
      Link.joins(:base_geometry)
        .select('links.id, base_geometries.id as geom_id, ST_AsGeoJSON(base_geometries.geom) as geom_json')
        .find_each {|res| geometries[res.geom_id] = res.geom_json}
      
      geometries
    end
  end
end
