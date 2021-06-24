# by default, comparative_fact is assigned with quantile breaks color scheme

class PerformanceMeasuresFactSymbologyService < ViewSymbologyService

  def configure_symbology
    # define same symbology for each column
    ["vehicle_miles_traveled", "vehicle_hours_traveled", "avg_speed"].each do |column_name|
      configure_symbology_for_column column_name
    end
  end

  private

  def configure_symbology_for_column(column_name)
    return nil if !@view

    index = @view.columns.find_index(column_name)
    label = @view.column_labels[index]

    # default symbology configs
    symbology_params = {
      is_default: true,
      view: @view,
      subject: label,
      symbology_type: Symbology::QUANTILE_BREAKS
    }

    # generate symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    # assign columns
    column_params = {
      name: column_name,
      title: label,
      symbology: symbology
    }
    column = Column.where(column_params).first_or_create
    symbology.update_attributes(default_column_index: column_name)
    
    # geometric breaks color scheme
    color_scheme_params = {
      symbology: symbology,
      start_color: "yellow",
      end_color: "red",
      class_count: 5
    }
    QuantileBreaksColorScheme.where(color_scheme_params).first_or_create
  end
end