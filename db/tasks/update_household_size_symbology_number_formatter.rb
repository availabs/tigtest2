formatter = NumberFormatter.where(format_type: 'number', options: "{\"format\":\"#,##0.##\",\"locale\":\"us\"}").first_or_create

hh_stat_view_ids = Statistic.joins(:views).where(name: 'Household Size').pluck "views.id"

Symbology.where(view_id: hh_stat_view_ids).update_all(number_formatter_id: formatter.id)
