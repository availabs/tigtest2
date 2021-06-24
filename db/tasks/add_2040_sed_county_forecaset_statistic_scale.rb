source_name = '2040 SED County Level Forecast Data'

source = Source.where(name: source_name).first

if source
  source.views.each do |view|
    next if view.name == '2000-2040 Household Size'
    view.statistic.update_attributes(scale: 3)
  end
end