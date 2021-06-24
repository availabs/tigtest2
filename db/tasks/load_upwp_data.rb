# Load UPWP Project data from mdb file.
# Two tables, Main Projects and Related Contracts.
# Assumes mbdtools has been installed.

source_attributes = {
  description: "Project and Related Contract details for NYMTC's Unified Planning Work Program"
}

puts 'Set Source'
source = Source.find_or_create_by(name: 'UPWP Projects')
source.update_attributes(source_attributes)

projects_name = 'UPWP Projects'
view_attributes = [{
  name: projects_name,
  description: 'Details of UPWP Projects',
  data_model: UpwpProject,
  columns: [:project_id, :name, :year, :project_category, :sponsor, :description, :agency_code, :total_staff_cost, :total_consultant_cost, :budgeted_other_cost, :deliverables],
  column_labels: ['PIN', 'Name', 'Year', 'Project Category', 'Sponsor', 'Description', 'Agency Code', 'Total Staff Cost', 'Total Consultant Cost', 'Budgeted Other Cost', 'Deliverables'],
  column_types: ['', '', '', '', '', '', '', 'currency', 'currency', 'currency' ],
  data_levels: ['Project']
                   }]

contracts_name = 'UPWP Related Contracts'
view_attributes << {
  name: contracts_name,
  description: 'Details of contracts associated with UPWP Projects',
  data_model: UpwpRelatedContract,
  columns: [:upwp_project, :contract_project_id, :name, :detail, :program_year, :budgeted_consultant_cost, :fhwa_carryover, :fta_carryover],
  column_labels: ['PIN', 'Contract PIN', 'Name', 'Detail', 'Program Year', 'Budgeted Consultant Cost', 'FHWA Carryover', 'FTA Carryover'],
  column_types: ['', '', '', '', '', 'currency', 'currency', 'currency' ],
  data_levels: ['Project']
}

view_actions = [:table, :view_metadata, :edit_metadata]

puts 'Set Views'
view_attributes.each do |attributes|
  view = source.views.where(name: attributes[:name]).first_or_create
  view.update_attributes(attributes)
  view_actions.each {|a| view.add_action(a)}
end

files = ['UPWP_new_version.mdb']

files.each do |file|
  db = Mdb.open(File.join(Rails.root, 'db', file))

  puts 'load Main Projects Table'
  # mdb Gem does not handle table names with spaces correctly so escape them here
  db["Main\\ Projects\\ Table"].each do |row|
    # find category and sponsor
    category = ProjectCategory.find_or_create_by(name: row[:Category])
    sponsor = Sponsor.find_or_create_by(name: row[:Sponsor])

    project = UpwpProject.find_or_create_by(
      project_id: row[:PIN],
      view: View.find_by(name: projects_name)
    )

    project.update_attributes(
      { 
        name: row[:"Project Name"],
        year: row[:yearin],
        project_category: category,
        sponsor: sponsor,
        agency_code: row[:"Agency Code"],
        description: row[:"Project Description"],
        total_staff_cost: row[:"Total Staff Cost"].to_f,
        total_consultant_cost: row[:"Total Consultant Cost"].to_f,
        budgeted_other_cost: row[:"Budgeted Other Cost"].to_f,
        deliverables: row[:Deliverables]
      })

  end

  puts 'load Related Contracts Table'
  # mdb Gem does not handle table names with spaces correctly so escape them here
  db["Related\\ Contracts\\ Table"].each do |row|
    # find project
    project = UpwpProject.find_by(project_id: row[:PIN])

    contract = UpwpRelatedContract.find_or_create_by(
      upwp_project: project,
      view: View.find_by(name: contracts_name), 
      contract_project_id: row[:"Contract PIN"],
      name: row[:"Contract Name"],
      program_year: row[:"Program Year"],
      actual_programmed_year: row[:"Actual Programmed"],
      budgeted_consultant_cost: row[:"Budgeted Consultant Cost"].to_f,
      detail: row[:Detail],
      fhwa_carryover: row[:"FHWA Carryover"].to_f,
      fta_carryover: row[:"FTA Carryover"].to_f
    ) if project
  end

end

