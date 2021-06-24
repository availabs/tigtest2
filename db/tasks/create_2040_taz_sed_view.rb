pop2020View = View.find_by_name('2020 Population Forecast')
pop2040View = View.find_by_name('2040 Population Forecast')
tazPopStat = Statistic.find_by_name("TAZ Population")

if pop2040View && tazPopStat
  columns = 2000.step(2040, 5).map { |year| year.to_s }
  columns.unshift 'area'
  column_types = columns.count.times.map {|| 'numeric' }
  column_types.unshift ''
  popTazView2040 = View.find_or_create_by(name: "2040 TAZ Population Forecast")
  
  popTazView2040.update_attributes(
                                data_starts_at: "2020-01-01",
                                data_ends_at: "2040-01-01",
                                description: "Population for 2040",
                                statistic: tazPopStat,
                                data_model: DemographicFact,
                                columns: columns,
                                column_types: column_types,
                                data_levels: [Area::AREA_LEVELS[:taz]], 
                                value_name: :value
                                )
  if !popTazView2040.source
    popTazView2040.update_attribute(:source, pop2040View.source)
  end
  popTazView2040.add_action :map
  popTazView2040.add_action :table
  popTazView2040.add_action :chart
  popTazView2040.add_action :metadata

  DemographicFact.where(statistic_id: tazPopStat.id, view_id: pop2040View.id).update_all(view_id: popTazView2040.id)

  puts 'Created create_2040_taz_sed_view and associated all available TAZ data with the new view'
else
  puts 'No available TAZ 2040 population forecast data loaded'
end

# update view names
pop2020View.update_attribute(:name, '2020 County Population Forecast') if pop2020View
pop2040View.update_attribute(:name, '2040 County Population Forecast') if pop2040View