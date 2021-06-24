class PerformanceMeasuresFactPresenter < AggregatePresenter

  def to_json(view = nil)
    super(view)
    # summary PerformanceFact looks like:
    # {
    #   "Mid Hudson South" => 120.0,
    #   "Long Island" => 144.0,
    #   ...
    # }
    case @chart_type
    when 'LineChart', 'AreaChart'
      cols = [{id: 'area_type', label:'Area Type', type: 'string'}]
      cols += series.collect do |s|
        {id: s.tr(' ', '').underscore, label: s, type: 'number'}
      end
      {
        cols: cols,
        rows: [{c: [{v: @aggregate_to.titleize}, series.collect{|s| {v: @facts[s]} }].flatten}]
      }
      # {
      #   cols: [{id: <measure>, label: <Measure>, type: 'string'},
      #          {id: 'kings', label: 'Kings', type: 'number'},
      #          {id: 'queens', label: 'Queens', type: 'number'}],
      #   ...],
      # rows: [{c:[{v: 'VMT'}, {v: 853080}, {v: 098308}, ...]}]
      #    }
      # ?? view.content_tag(:time, facts.published_at.strftime("%A, %B %e"))
    when 'BarChart'
      barchart_to_json
    end
  end

end