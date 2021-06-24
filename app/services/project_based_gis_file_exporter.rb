#
# RtpProject, TipProject: includes data for multiple geometry types, so need to export one gemetry type as one shapefile
#
class ProjectBasedGisFileExporter < AbstractGisFileExporter
  attr_reader :data, :geojson_paths
  
  def initialize( file_name, data = [])  
    super(file_name)
    @data = data || []
    @geojson_paths = {}
    puts @tmp_dir
  end

  def to_geojson  
    features = {}
    factory = RGeo::Geos.factory(:srid => 4326)
    wkt_parser = RGeo::WKRep::WKTParser.new if !factory
    @data.each do |r|
      if factory
        geom = factory.parse_wkt(r[:geography]) rescue nil 
      elsif 
        geom = wkt_parser.parse(r[:geography]) rescue nil 
      end
        
      next if !geom

      geom_type = geom.geometry_type.type_name
      sub_features = features[geom_type] 
      if !sub_features
        features[geom_type] = []
        sub_features = features[geom_type]
      end

      sub_features << Geojson::Feature.new(
        r.except(:geography), 
        RGeo::GeoJSON.encode(geom)
      )
    end

    features.each do |geom_type, data|
      save_geojson_file geom_type, Geojson::FeatureCollection.new(data)
    end
  end

  def save_geojson_file(geom_type, features)
    geojson_path = File.join(@tmp_dir, "#{@file_name}_#{geom_type}.geojson") 

    File.open(geojson_path, 'w') do |f|
      f.write features.to_json
    end

    @geojson_paths[geom_type] = geojson_path
  end

  def geojson_to_shapefile
    to_geojson
    puts 'paths for each geometry type geojson file:'
    puts @geojson_paths
    @geojson_paths.each do |type, geojson_path|
      # Concert to shp
      #Kernel.system 'ogr2ogr', '-a_srs', 'EPSG:4326', '-skipfailures', '-f', 'ESRI Shapefile', shp_path(type), geojson_path, 'OGRGeoJSON'
      Delayed::Worker.logger.debug('ogr2ogr -a_srs EPSG:4326 -skipfailures -f "ESRI Shapefile" ' +  shp_path(type) + ' ' + geojson_path)
      Delayed::Worker.logger.debug(Kernel.system 'echo *')
      Delayed::Worker.logger.debug(Kernel.system 'ogr2ogr', '-a_srs', 'EPSG:4326', '-skipfailures', '-f', 'ESRI Shapefile', shp_path(type), geojson_path)
    end
  end

  def shp_path(geom_type)
    File.join(@shp_folder_path, "#{@file_name}_#{geom_type}.shp") # the output
  end
end