module Geojson
  class FeatureCollection
    SIMPLIFY_TOLERANCE = 0.0001;
    attr_accessor :type, :features

    def initialize(features = [])
      @type = 'FeatureCollection'
      @features = features || []
    end
  end
end