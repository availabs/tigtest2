view = View.find_by(name: "UPWP Related Contracts")
unless view.columns[1] == 'Project Name'
  cols = view.columns.insert(1, [:project_name, :project_description, :project_year, :project_category, :project_sponsor]).flatten
  col_labels = view.column_labels.insert(1, ['Project Name', 'Project Description', 'Project Year', 'Project Category', 'Project Sponsor']).flatten
  col_types = view.column_types.insert(1, ['','','','','']).flatten

  view.update_attribute('columns', cols)
  view.update_attribute('column_labels', col_labels)
  view.update_attribute('column_types', col_types)
end
