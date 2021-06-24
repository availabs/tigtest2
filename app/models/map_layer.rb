class MapLayer < ActiveRecord::Base
  validates_presence_of :layer_type, :name, :url, :category, :geometry_type, :version
  validates :reference_column, presence: true, if: :is_vector_tile?
  validates :category, uniqueness: { scope: :version,
    message: "Can only have one category per version" }

  def self.get_layer_config(a_category, a_version = nil)
    if a_version
      where(category: a_category.to_s, version: a_version.to_s).first.try(:as_json)
    else
      where(category: a_category.to_s).first.try(:as_json)
    end
  end

  def is_vector_tile?
    layer_type == 'PBF_TILE'
  end

  def is_geojson?
    layer_type == 'Geojson'
  end

  def as_json 
    {
      type: layer_type,
      category: category,
      version: version,
      url: url,
      tileName: name,
      geomReferenceColumn: reference_column,
      name: title || name,
      geometry_type: geometry_type,
      turn_off_by_default: !visibility,
      showLabel: label_visibility,
      labelColumnName: label_column,
      attribution: attribution,
      style: eval(style || 'nil'),
      highlightStyle: eval(highlight_style || 'nil'),
      predefined_symbology: eval(predefined_symbology || 'nil')
    }
  end

end
