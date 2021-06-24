class DemographicFactPresenter < AggregatePresenter
  
  def to_json(view = nil)
    super(view)
    # summary DemographicFact looks like:
    # {
    #   [ 2025, "Mid Hudson South" ] => 308770.0,
    #   [ 2010, "Mid Hudson" ]       => 434374.0,
    #   ...
    # }
    years = @facts.collect{|k, v| k[0]}.uniq.sort
    case @chart_type
    when 'LineChart', 'AreaChart'
      series = @facts.collect{|k, v| k[1]}.uniq.sort
      cols = [{id: 'year', label: 'Year', type: 'string'}]
      cols += series.collect do |s|
        {id: s.tr(' ', '').underscore, label: s, type: 'number'}
      end
      {
        cols: cols,
        rows: years.collect do |y|
          {c: [{v: y}, series.collect{|s| {v: @facts[[y, s]]} }].flatten}
        end
      }
      # {
      #   cols: [{id: 'year', label: 'Year', type: 'string'},
      #          {id: 'kings', label: 'Kings', type: 'number'},
      #          {id: 'queens', label: 'Queens', type: 'number'}],
      #   ...],
      # rows: [{c:[{v: '2010'}, {v: 853080}, {v: 098308}, ...]},
      #        {c:[{v: '2015'}, {v: 583405}, {v: 584390}, ...]},
      #        ...]
      #    }
      #     ?? view.content_tag(:time, facts.published_at.strftime("%A, %B %e"))
    when 'BarChart', 'PieChart'
      barchart_to_json &:last
    end
  end

end
