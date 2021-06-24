class ComparativeFactPresenter < AggregatePresenter

  def to_json(view = nil)
    super(view)
    # summary ComparativeFact looks like:
    # {
    #   "Mid Hudson South" => 120.0,
    #   "Long Island" => 144.0,
    #   ...
    # }
    case @chart_type
    when 'BarChart', 'PieChart'
      barchart_to_json
    end
  end

end