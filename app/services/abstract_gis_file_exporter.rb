class AbstractGisFileExporter
  attr_reader :file_name, :tmp_dir, :shp_folder_path
  
  def initialize(file_name)
    @file_name = file_name.underscore.tr ' ', '_' rescue 'export'
    @tmp_dir = get_tmp_dir
    @shp_folder_path = get_shp_folder_path
  end

  def export_shp
    geojson_to_shapefile
    puts @shp_folder_path
    zip_folder @shp_folder_path
  end

  def to_geojson_string
    "{}"
  end

  def save_geojson_file
    geojson_path = File.join(@tmp_dir, "#{@file_name}.geojson") 

    File.open(geojson_path, 'w') do |f|
      f.write to_geojson_string
    end

    geojson_path
  end

  def geojson_to_shapefile
    geojson_path = save_geojson_file
    Delayed::Worker.logger.debug("<AbstractGisFileExporter> geojson_to_shapefile" + geojson_path + " / " + shp_path)
    Delayed::Worker.logger.debug('ogr2ogr -a_srs EPSG:4326 -skipfailures -f ESRI Shapefile '+  shp_path + ' ' + geojson_path +  ' OGRGeoJSON')
    # Concert to shp
    Delayed::Worker.logger.debug(Kernel.system 'ogr2ogr', '-a_srs', 'EPSG:4326', '-skipfailures', '-f', 'ESRI Shapefile', shp_path, geojson_path)
  end

  def shp_path
    File.join(@shp_folder_path, "#{@file_name}.shp") # the output
  end

  def get_tmp_dir
    require 'tmpdir'
    Dir.mktmpdir
  end

  def get_shp_folder_path
    path = File.join(@tmp_dir, @file_name)

    Dir.mkdir path if !File.directory?(path)

    path
  end

  def zip_folder(dir)
    puts "zipping #{dir}"
    zip_file = dir + '.zip'
    zf = ZipFileGenerator.new(dir, zip_file)
    zf.write()

    zip_file
  end

  def delete_tmp_dir
    require 'fileutils'
    FileUtils.rm_rf @tmp_dir
  end
end