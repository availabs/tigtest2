# by default, bpm_summary_fact is assigned with a geometric breaks color scheme

class BpmSummaryFactSymbologyService < ViewSymbologyService

  def configure_symbology
    return nil if !@view

    # default symbology configs
    symbology_params = {
      is_default: true,
      view: @view,
      subject: 'TAZ Counts',
      symbology_type: Symbology::GEOMETRIC_BREAKS,
      number_formatter:  NumberFormatter.where(format_type: 'number', options:{
        format: '#,##0', 
        locale: 'us'
        }.to_json).first_or_create
    }

    # generate symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    # assign columns
    column_params = {
      name: 'count',
      title: 'Counts',
      symbology: symbology
    }
    column = Column.where(column_params).first_or_create
    symbology.update_attributes(default_column_index: column.name)
    
    # geometric breaks color scheme
    color_scheme_params = {
      symbology: symbology,
      start_color: "#ffeda0",
      end_color: "#800026",
      gap_value: 400,
      multiplier: 1.5
    }
    GeometricBreaksColorScheme.where(color_scheme_params).first_or_create
  end
end