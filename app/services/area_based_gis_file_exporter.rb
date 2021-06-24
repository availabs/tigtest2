class AreaBasedGisFileExporter < AbstractGisFileExporter
  attr_reader :data, :geom_match_column, :area_type
  
  def initialize( file_name, data, area_type, year, geom_match_column = 'area')  
    super(file_name)

    @data, @geom_match_column, @area_type, @year = data, geom_match_column, area_type, year
  end

  def to_geojson_string  
    data_hash = {}
    area_names = []

    @data.each do |r|
      area_name = r[@geom_match_column]
      area_names << area_name

      data_hash[area_name] = r
    end

    areas = Area.joins(:base_geometry).select("areas.id", :name, :base_geometry_id)
    if @area_type.blank?
      areas = areas.where(name: area_names)
    else
      areas = areas.where(type: @area_type, name: area_names)
    end

    unless @year.blank?
      areas = areas.where(year: @year)
    end

    features = []
    geometries = Area.geometries(@area_type)
    areas.find_each do |r|
      geom_id = r.base_geometry_id
      if geom_id.blank?
        next
      end

      features << "{\"type\":\"Feature\",\"properties\":#{data_hash[r.name].to_json},\"geometry\": #{geometries[geom_id]}}"
    end

    "{\"type\":\"FeatureCollection\",\"features\":[#{features.join(',')}]}"
  end
end