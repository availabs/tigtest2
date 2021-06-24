class CountFactPresenter < AggregatePresenter
  
  def to_json(view = nil)
    super(view)

    hours = (0..23).to_a
    case @chart_series.to_s
    when "direction"
      series_label = 'Direction'
      series = ['Inbound', 'Outbound']
    when "transit_mode"
      series_label = 'Mode'
      series = TransitMode.order(:name).pluck(:name)
    when "sector"
      series_label = 'Sector'
      series = Sector.order(:name).pluck(:name)
    end
    
    case @chart_type 
    when 'LineChart'
      cols = [{id: 'hour', label: 'Hour', type: 'string'}]
      cols += series.collect do |s|
        {id: s.tr(' ', '').underscore, label: s, type: 'number'}
      end
      {
        cols: cols,
        rows: hours.collect do |y|
          {c: [{v: format('%02d:00', y)}, series.collect{|s| {v: @facts[[y, s]]} }].flatten}
        end
      }
    when 'BarChart'
      # handle nil values (https://stackoverflow.com/questions/808318/sorting-a-ruby-array-of-objects-by-an-attribute-that-could-be-nil)
      # except sort nil first so that it's last after the reverse
      data = @facts.sort{|a, b| a.last && b.last ? a.last <=> b.last : a.last ? 1 : -1}.reverse
      rows = data.collect do |d|
        name = series_label == 'Mode' ? clean_name(d[0]) : d[0]
        {c: [{v: name}, {v: d[1]}]}
      end
      {
        cols: [{label: series_label, type: 'string'}, {label: '', type: 'number'}],
        rows: rows
      }
    end
  end

  protected

  def clean_name(name)
    name = 'Vehicles' if name.include? 'Vehicles'
    name.sub("Rail Rapid Transit", "RRT")
  end
end
