# by default, count_fact is assigned with unique value color scheme

class CountFactSymbologyService < ViewSymbologyService

  def configure_symbology
    return nil if !@view

    # default symbology configs
    symbology_params = {
      is_default: true,
      view: @view,
      subject: 'Sector',
      symbology_type: Symbology::UNIQUE_VALUE,
      number_formatter:  NumberFormatter.where(format_type: 'number', options:{
        format: '#,##0.##', 
        locale: 'us'
        }.to_json).first_or_create
    }

    # generate symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    # assign columns
    column_params = {
      name: 'sector_name',
      title: 'Sectors',
      symbology: symbology
    }
    column = Column.where(column_params).first_or_create
    symbology.update_attributes(default_column_index: column.name)
    
    # unique value colors
    color_configs = [
      {
        color: "rgb(0, 255, 255)",
        value: "60th Street Sector",
        label: "60th Street Sector"
        },
      {
        color: "rgb(0, 255, 0)",
        value: "Brooklyn",
        label: "Brooklyn"
        },
      {
        color: "rgb(255, 0, 255)",
        value: "Staten Island",
        label: "Staten Island"
        },
      {
        color: "rgb(0, 0, 255)",
        value: "Queens",
        label: "Queens"
        },
      {
        color: "rgb(255, 0, 0)",
        value: "New Jersey",
        label: "New Jersey"
        }
    ]

    color_configs.each do | color_config |
      UniqueValueColorScheme.where(color_config.merge(symbology: symbology)).first_or_create
    end
  end
end