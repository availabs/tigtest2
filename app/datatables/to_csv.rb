module ToCsv
  def to_csv(view)
    CSV.generate do |csv|
      visible_columns = []
      csv << [view.title] if view
      csv << params[:columns].map do |k,v|
        if view.column_labels
          view.column_labels[v["data"].to_i] if v["visible"] == "true"
        else
          view.columns[v["data"].to_i].to_s.titleize if v["visible"] == "true"
        end
      end.compact

      params[:columns].map{ |k,v|
        visible_columns << v["data"].to_i if v["visible"] == "true"
      }.compact

      data.each { |fact| 
        csv << visible_columns.map { |id| fact[id] }
      }
    end
  end
end
