# Default color scheme for speed_fact is custom breaks

class SpeedFactSymbologyService < ViewSymbologyService
  def configure_symbology
    return nil if !@view

    # default symbology configs
    symbology_params = {
      is_default: true,
      view: @view,
      subject: 'Average Speed (mph)',
      symbology_type: Symbology::CUSTOM_BREAKS
    }

    # generate symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    # assign columns
    column_params = {
      name: 'speed',
      title: 'Avg. Speed (mph)',
      symbology: symbology
    }
    column = Column.where(column_params).first_or_create
    symbology.update_attributes(default_column_index: column.name)
    
    # custom breaks color scheme
    color_configs = [
      {
        color: "rgb(255, 0, 0)",
        min_value: 0,
        max_value: 10
        },
      {
        color: "rgb(255, 100, 0)",
        min_value: 10,
        max_value: 20
      },
      {
        color: "rgb(255, 255, 0)",
        min_value: 20,
        max_value: 30
      },
      {
        color: "rgb(0, 100, 255)",
        min_value: 30,
        max_value: 40
      },
      {
        color: "rgb(0, 0, 255)",
        min_value: 40,
        max_value: 45
      },
      {
        color: "rgb(0, 255, 255)",
        min_value: 45,
        max_value: 50
      },
      {
        color: "rgb(0, 100, 100)",
        min_value: 50,
        max_value: 55
      },
      {
        color: "rgb(0, 255, 0)",
        min_value: 55
      }
    ]

    color_configs.each do | color_config |
      CustomBreaksColorScheme.where(color_config.merge(symbology: symbology)).first_or_create
    end
  end
end