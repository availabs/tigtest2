# by default, comparative_fact is assigned with quantile breaks color scheme

class ComparativeFactSymbologyService < ViewSymbologyService

  def configure_symbology
    configure_percent_symbology
    configure_value_symbology
  end

  private
  
  def configure_percent_symbology
    return nil if !@view

    percent_index = @view.columns.find_index('percent')
    percent_column_label = @view.column_labels[percent_index]

    # default symbology configs
    symbology_params = {
      is_default: true,
      view: @view,
      subject: percent_column_label,
      symbology_type: Symbology::QUANTILE_BREAKS,
      number_formatter:  NumberFormatter.where(
        format_type: 'percent', 
        options: {decimal: 2}.to_json).first_or_create #TODO
    }

    # generate symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    # assign columns
    column_params = {
      name: 'percent',
      title: percent_column_label,
      symbology: symbology
    }
    column = Column.where(column_params).first_or_create
    symbology.update_attributes(default_column_index: column.name)
    
    # geometric breaks color scheme
    color_scheme_params = {
      symbology: symbology,
      start_color: "yellow",
      end_color: "red",
      class_count: 5
    }
    QuantileBreaksColorScheme.where(color_scheme_params).first_or_create
  end

  def configure_value_symbology
    return nil if !@view

    value_index = @view.columns.find_index('value')
    value_column_label = @view.column_labels[value_index]

    # default symbology configs
    symbology_params = {
      is_default: true,
      view: @view,
      subject: value_column_label,
      symbology_type: Symbology::QUANTILE_BREAKS,
      number_formatter:  NumberFormatter.where(format_type: 'number', options: {
          format:"#,##0", 
          locale:"us"
        }.to_json).first_or_create #TODO
    }

    # generate symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    # assign columns
    column_params = {
      name: 'value',
      title: value_column_label,
      symbology: symbology
    }
    column = Column.where(column_params).first_or_create
    symbology.update_attributes(default_column_index: column.name)
    
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