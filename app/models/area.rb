class Area < ActiveRecord::Base
  extend NamedValue
  include DisplayName

  has_many :areas_enclosed, source: :area_enclosures, foreign_key: "enclosing_area_id", class_name: "AreaEnclosure"
  has_many :areas_enclosing, source: :area_enclosures, foreign_key: "enclosed_area_id", class_name: "AreaEnclosure"
  has_many :enclosed_areas, through: :areas_enclosed
  has_many :enclosing_areas, through: :areas_enclosing
  belongs_to :base_geometry
  
  attr_accessible :name, :type, :enclosing_areas, :enclosed_areas, :size, :fips_code
                          
  # by default ActiveRecord uses type for single record inheritance. Disable for now.
  Area.inheritance_column = 'none'

  # Area level constants
  AREA_LEVELS = {
    region: 'region',
    subregion: 'subregion',
    tcc: 'tcc',
    county: 'county',
    census_tract: 'census_tract',
    taz: 'taz'
  }

  AREA_LEVEL_DISPLAY = {
    region: 'Region',
    subregion: 'Sub Region',
    tcc: 'TCC',
    county: 'County',
    census_tract: 'Census Tract',
    taz: 'TAZ'
  }

  scope :regions, -> { where(type: AREA_LEVELS[:region]) }
  scope :subregions, -> { where(type: AREA_LEVELS[:subregion]) }
  scope :tccs, -> { where(type: AREA_LEVELS[:tcc]) }
  scope :counties, -> { where(type: AREA_LEVELS[:county]) }
  scope :census_tracts, -> { where(type: AREA_LEVELS[:census_tract]) }
  scope :tazs, -> { where(type: AREA_LEVELS[:taz]) }

  def self.is_versioned?(area_type)
    [:taz, :census_tract].index(area_type.to_sym) ? true : false
  end

  def self.years_by(type)
    Area.where(type: type).pluck(:year).uniq
  end

  def self.loadCSV(filename)
    CSV.foreach(filename, headers: true, return_headers: false) do |row|
      name = row['area']
      next if name.nil?
      area = Area.find_or_create_by( name: name.titleize )
      size = row['size']
      area.update_attributes(size: size.to_f) if size
    end
    
  end

  def self.convertJson2Csv(jsonFile, csvFile)
    json = JSON.parse(File.read(jsonFile))

    CSV.open(csvFile, 'wb') do |csv|
      row = Array.new(2)
      json['features'].each do |feature|
        prop = feature['properties']
        row[0] = prop['TAZ_ID']
        row[1] = prop['AREA']

        csv << row
      end
    end
    true
  end

  def self.parse(geography, area_level, fips=nil)
    case area_level
    when :census_tract
      match = /Census Tract ([^,]*), (.*) County, (.*)/.match(geography)
      tract = Area.where(name: "#{match[2]}:#{match[1]}", type: AREA_LEVELS[area_level]).first_or_create
      county = Area.where(name: match[2], type: AREA_LEVELS[:county]).first_or_create

      tract.enclosing_areas << county unless tract.enclosing_areas.include? county
      # TODO: sanity check fips code should match county and tract number
      tract.update_attributes(fips_code: fips) if fips
      tract
    end
  end

  def self.parse_area_type(view_level)
    view_level = view_level || ''
    Area::AREA_LEVELS[view_level.downcase.underscore.to_sym]
  end

  def self.parse_area_type_name(view_level)
    view_level = view_level || ''
    Area::AREA_LEVEL_DISPLAY[view_level.downcase.underscore.to_sym]
  end

  def is_county?
    type == Area::AREA_LEVELS[:county]
  end

  def is_subregion?
    type == Area::AREA_LEVELS[:subregion]
  end

  def is_study_area?
    type.try(:to_sym) == :study_area  
  end

  def geom_as_wkt
    base_geometry.geom.envelope.as_text if base_geometry && base_geometry.geom
  end

  def self.geometries(type)
    Rails.cache.fetch("area_#{type.to_s.underscore}_geometries") do
      puts "area geometries null: #{type}"
      geometries = Hash.new
      #geom_geojson_str = "base_geometries.id as geom_id, ST_AsGeoJSON(ST_Simplify(base_geometries.geom, #{Geojson::FeatureCollection::SIMPLIFY_TOLERANCE})) as geom_json"
      geom_geojson_str = "areas.id, base_geometries.id as geom_id, ST_AsGeoJSON(base_geometries.geom) as geom_json"
      Area.joins(:base_geometry).select(geom_geojson_str).where(:type => type).find_each {|res| geometries[res.geom_id] = res.geom_json}

      geometries
    end
  end
  
end
