class TmcBasedGisFileExporter < AbstractGisFileExporter
  attr_reader :view_name, :filters
  
  def initialize( view_name, filters)  
    @view_name, @filters = view_name, filters
    super(get_file_name)
  end

  def prepare_data
    SpeedFact.get_data(
      @filters[:year], 
      @filters[:month], 
      @filters[:day_of_week], 
      @filters[:hour], 
      @filters[:vehicle_class], 
      @filters[:direction], 
      @filters[:area], 
      @filters[:lower], 
      @filters[:upper],
      true
    )
  end

  def to_geojson_string
    Delayed::Worker.logger.debug("<TmcBasedGisFileExporter> to_geojson_string")
    geometries = Tmc.geometries
    Delayed::Worker.logger.debug("<TmcBasedGisFileExporter> geometries length" + geometries.length.to_s)
    features = []
    data = prepare_data
    Delayed::Worker.logger.debug("<TmcBasedGisFileExporter> data length" + data.length.to_s)
    data.each do |r|
      geom_id = r.base_geometry_id
      if geom_id.blank?
        next
      end
      
      features << "{\"type\":\"Feature\",\"properties\":#{r.attributes.except("id", "base_geometry_id").to_json},\"geometry\": #{geometries[geom_id]}}"

    end
    # Delayed::Worker.logger.debug("{\"type\":\"FeatureCollection\",\"features\":[#{features.join(',')}]}")
    "{\"type\":\"FeatureCollection\",\"features\":[#{features.join(',')}]}"
  end

  def get_file_name
    day_of_weeks = @filters[:day_of_week].to_s.split
    if day_of_weeks.size > 1
      day_of_week = day_of_weeks.index(SpeedFact.day_of_weeks[:monday].to_s) ? 'weekdays' : 'weekend'
    else
      day_of_week = SpeedFact.day_of_weeks.key(@filters[:day_of_week].to_i).to_s
    end

    base_name = ("%s_%s_%s_%s_%s_%s_%s" % [
      view_name, 
      @filters[:year], 
      @filters[:month], 
      day_of_week, 
      @filters[:hour], 
      SpeedFact.vehicle_classes.key(@filters[:vehicle_class].to_i).to_s, 
      @filters[:direction], 
      @filters[:area].try(:name)
      ]).strip

    base_name += "_from_#{@filters[:lower]}" if @filters[:lower].present?
    base_name += "_to_#{@filters[:upper]}" if @filters[:upper].present?

    base_name
  end
end