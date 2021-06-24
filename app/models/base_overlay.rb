class BaseOverlay < ActiveRecord::Base
  belongs_to :base_geometry

  OVERLAY_TYPES = {
    :uab => 'urban_area_boundary',
    :hub_bound => 'hub_bound',
    :bpm_highway => 'bpm_highway'
  }


  def self.geojson(type)
    Rails.cache.fetch("baseoverlay_#{type.underscore}_geojson") do
      geojson ||= Hash.new do|h, k|
        puts 'base overlay null'
        #geom_geojson_str = "ST_AsGeoJSON(ST_Simplify(base_geometries.geom, #{Geojson::FeatureCollection::SIMPLIFY_TOLERANCE})) as geom_geojson"
        geom_geojson_str = "ST_AsGeoJSON(base_geometries.geom) as geom_geojson"
        records = BaseOverlay.joins(:base_geometry).select(:properties, geom_geojson_str).where(:overlay_type => k)

        features = []
        records.each do |r|
          if !r.geom_geojson
            next
          end
          features << Geojson::Feature.new(
            JSON.parse(r.properties), 
            JSON.parse(r.geom_geojson)
          )
        end

        h[k] = Geojson::FeatureCollection.new(features)
      end

      geojson[type]
    end
  end
end
