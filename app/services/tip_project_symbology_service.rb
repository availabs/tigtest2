# by default, tip_project is assigned with unique value color scheme

class TipProjectSymbologyService < ViewSymbologyService

  def configure_symbology(params={})
    return nil if !@view

    # default symbology configs
    symbology_params = {
      is_default: true,
      view: @view,
      subject: 'TIP Projects',
      symbology_type: Symbology::UNIQUE_VALUE
    }.merge(params)

    # generate symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    # assign columns
    Column.where(symbology: symbology).delete_all
    column_params = {
      name: 'ptype',
      title: 'Ptype',
      symbology: symbology
    }
    column = Column.where(column_params).first_or_create
    symbology.update_attributes(default_column_index: column.name)
    
    # unique value colors
    color_configs = [
      {
        color: "#38A800",
        value: "Bike",
        label: "Bike"
      },
      {
        color: "#0070FF",
        value: "Bus",
        label: "Bus"
      },
      {
        color: "#D79E9E",
        value: "Ferry",
        label: "Ferry"
      },
      {
        color: "#FFF",
        value: "Highway",
        label: "Highway"
      },
      {
        color: "#FF00C5",
        value: "ITS",
        label: "ITS"
      },
      {
        color: "#B1FF00",
        value: "Pedestrian",
        label: "Pedestrian"
      },
      {
        color: "#9C9C9C",
        value: "Rail",
        label: "Rail"
      },
      {
        color: "#FFAA00",
        value: "Study",
        label: "Study"
      },
      {
        color: "#00C5FF",
        value: "Transit",
        label: "Transit"
      },
      {
        color: "#000",
        value: "Truck",
        label: "Truck"
      },
      {
        color: "#496bff",
        value: "Parking",
        label: "Parking"
      },
      {
        color: "#ffeb3b",
        value: "Historic",
        label: "Historic"
      }
    ]

    color_configs.each do | color_config |
      UniqueValueColorScheme.where(color_config.merge(symbology: symbology)).first_or_create
    end
  end
end
