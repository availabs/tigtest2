class LinkBasedGisFileExporter < AbstractGisFileExporter
  attr_reader :view_name, :filters
  
  def initialize( view_name, filters)  
    @view_name, @filters = view_name, filters
    super(get_file_name)
  end

  def prepare_data
    LinkSpeedFact.get_data(
      @filters[:year], 
      @filters[:month], 
      @filters[:day_of_week], 
      @filters[:hour],  
      @filters[:direction], 
      @filters[:area], 
      @filters[:lower], 
      @filters[:upper],
      true
    )
  end

  def to_geojson_string  
    geometries = Link.geometries
    features = []
    data = prepare_data
    if data
      data.select("link_speed_facts.id").find_each do |r|
        geom_id = r.base_geometry_id
        if geom_id.blank?
          next
        end
        
        features << "{\"type\":\"Feature\",\"properties\":#{r.attributes.except("id", "base_geometry_id").to_json},\"geometry\": #{geometries[geom_id]}}"
      
      end
    end

    "{\"type\":\"FeatureCollection\",\"features\":[#{features.join(',')}]}"

  end

  def get_file_name
    base_name = ("%s_%s_%s_%s_%s_%s_%s" % [
      view_name, 
      @filters[:year], 
      @filters[:month], 
      LinkSpeedFact.day_of_weeks.key(@filters[:day_of_week].to_i).to_s, 
      @filters[:hour], 
      @filters[:direction], 
      @filters[:area].try(:name)
      ]).strip

    base_name += "_from_#{@filters[:lower]}" if @filters[:lower].present?
    base_name += "_to_#{@filters[:upper]}" if @filters[:upper].present?

    base_name
  end
end