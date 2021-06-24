class SpeedFactPresenter < AggregatePresenter
  
  def to_json(view = nil)
    super(view)
    # summary SpeedFact looks like:
    # {
    #   [ 1, "Mid Hudson South" ] => 30.0,
    #   [ 2, "Mid Hudson" ]       => 43.0,
    #   ...
    # }
    hours = @facts.collect{|k, v| k[0]}.uniq.sort
    case @chart_type
    when 'LineChart', 'AreaChart'
      series = @facts.collect{|k, v| k[1]}.uniq.sort
      cols = [{id: 'hour', label: 'Hour', type: 'string'}]
      cols += series.collect do |s|
        {id: s.tr(' ', '').underscore, label: s, type: 'number'}
      end
      {
        cols: cols,
        rows: hours.collect do |y|
          display_y = @zero_based ? y : y - 1 
          {c: [{v: format('%02d:00', display_y)}, series.collect{|s| {v: @facts[[y, s]]} }].flatten}
        end
      }
      # {
      #   cols: [{id: 'hour', label: 'Hour', type: 'string'},
      #          {id: 'kings', label: 'Kings', type: 'number'},
      #          {id: 'queens', label: 'Queens', type: 'number'}],
      #   ...],
      # rows: [{c:[{v: '2'}, {v: 53}, {v: 30}, ...]},
      #        {c:[{v: '2'}, {v: 58}, {v: 58}, ...]},
      #        ...]
      #    }
      #     ?? view.content_tag(:time, facts.published_at.strftime("%A, %B %e"))
    when 'BarChart'
      barchart_to_json &:last
    end
  end

end
