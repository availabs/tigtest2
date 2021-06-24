module Geojson
  class Feature
    attr_accessor :type, :properties, :geometry

    def initialize(properties = nil, geometry = nil)
      @type = 'Feature'
      @properties = properties
      @geometry = geometry
    end
  end
end