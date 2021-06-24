class CountBasedGisFileExporter < AbstractGisFileExporter
  attr_reader :view_name, :filters
  
  def initialize( view_name, filters)  
    @view_name, @filters = view_name, filters
    super(get_file_name)
  end

  def prepare_data
    CountFact.get_data(
      @filters[:view], 
      @filters[:year], 
      @filters[:hour], 
      @filters[:current_mode], 
      @filters[:current_direction],
      @filters[:area], 
      @filters[:lower],
      @filters[:upper]
      )
  end

  def to_geojson_string  
    features = []
    data = prepare_data
    if data
      data.select("count_facts.id").find_each do |r|
        geom =
          {
            "type": "Point",
            "coordinates": [r.lng, r.lat]
          }
        
        features << "{\"type\":\"Feature\",\"properties\":#{r.attributes.except("id").to_json},\"geometry\": #{geom.to_json}}"

      end
    end

    "{\"type\":\"FeatureCollection\",\"features\":[#{features.join(',')}]}"
  end

  def get_file_name
    transit_mode_name = TransitMode.find(@filters[:current_mode].to_i).name if !@filters[:current_mode].blank? rescue nil
    from_hour = @filters[:hour].first rescue nil
    to_hour = @filters[:hour].last rescue from_hour
    base_name = ("%s_year_%s_hour_%s_%s_%s_%s_%s" % [
      @view_name, 
      @filters[:year], 
      from_hour, 
      to_hour, 
      transit_mode_name, 
      @filters[:current_direction], 
      @filters[:area].try(:name)
      ]).strip

    base_name += "_from_#{@filters[:lower]}" if @filters[:lower].present?
    base_name += "_to_#{@filters[:upper]}" if @filters[:upper].present?

    base_name
  end
end