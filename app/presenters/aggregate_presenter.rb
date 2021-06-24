class AggregatePresenter
  include ActionView::Helpers::NumberHelper

  def self.create(model, facts, chart_type, aggregate_to = nil, chart_series = nil)
    if model == DemographicFact
      DemographicFactPresenter.new(facts, chart_type, false, aggregate_to)
    elsif [SpeedFact, LinkSpeedFact].include? model
      SpeedFactPresenter.new(facts, chart_type, (model == LinkSpeedFact), aggregate_to)
    elsif model == PerformanceMeasuresFact
      PerformanceMeasuresFactPresenter.new(facts, chart_type, false, aggregate_to)
    elsif model == ComparativeFact
      ComparativeFactPresenter.new(facts, chart_type, false, aggregate_to)
    elsif model == CountFact
      CountFactPresenter.new(facts, chart_type, false, nil, chart_series)
    end
  end

  def initialize(facts, chart_type, zero_based = false, aggregate_to = nil, chart_series = nil)
   @facts = facts
   @chart_type = chart_type
   @zero_based = zero_based
   @aggregate_to = aggregate_to
   @chart_series = chart_series
  end

  def to_json(view = nil)
    # Rails.logger.debug @facts
  end

  protected

  attr_reader :facts

  def barchart_to_json(&block)
    # handle nil values (https://stackoverflow.com/questions/808318/sorting-a-ruby-array-of-objects-by-an-attribute-that-could-be-nil)
    # except sort nil first so that it's last after the reverse
    data = @facts.sort{|a, b| a.last && b.last ? a.last <=> b.last : a.last ? 1 : -1}.reverse
    rows = data.collect do |d|
      v = block_given? ? yield(d[0]) : d[0]
      {c: [{v: v}, {v: d[1].try(:to_f)}]}
    end
    {
      cols: [{label: @aggregate_to.titleize, type: 'string'}, {label: '', type: 'number'}],
      rows: rows
    }
  end

  # format number as % in tooltip
  def pct_barchart_to_json(&block)
    # handle nil values (https://stackoverflow.com/questions/808318/sorting-a-ruby-array-of-objects-by-an-attribute-that-could-be-nil)
    # except sort nil first so that it's last after the reverse
    data = @facts.sort{|a, b| a.last && b.last ? a.last <=> b.last : a.last ? 1 : -1}.reverse
    rows = data.collect do |d|
      v = block_given? ? yield(d[0]) : d[0]
      {c: [{v: v}, {v: d[1], f: "#{d[1]*100.0}%"}]}
    end
    {
      cols: [{label: @aggregate_to.titleize, type: 'string'}, {label: '', type: 'number'}],
      rows: rows
    }
  end

  # format number as % in tooltip
  def pct_barchart_to_json(&block)
    # handle nil values (https://stackoverflow.com/questions/808318/sorting-a-ruby-array-of-objects-by-an-attribute-that-could-be-nil)
    # except sort nil first so that it's last after the reverse
    data = @facts.sort{|a, b| a.last && b.last ? a.last <=> b.last : a.last ? 1 : -1}.reverse
    rows = data.collect do |d|
      v = block_given? ? yield(d[0]) : d[0]
      {c: [{v: v}, {v: d[1], f: "#{d[1]*100.0}%"}]}
    end
    {
      cols: [{label: @aggregate_to.titleize, type: 'string'}, {label: '', type: 'number'}],
      rows: rows
    }
  end
end
