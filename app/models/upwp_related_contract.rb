class UpwpRelatedContract < ActiveRecord::Base
  belongs_to :upwp_project, counter_cache: :num_contracts
  belongs_to :view

  default_scope { includes(upwp_project: [:project_category, :sponsor]) }

  def self.pivot?
    false
  end

   def self.sortable_searchable_columns(view)
    view.columns.collect do |col|
      case col
      when :upwp_project
        "UpwpProject.name"
      when /^project_(?<col>.*)/
        "UpwpProject.#{$LAST_MATCH_INFO[:col]}"
      else
        "UpwpRelatedContract.#{col}"
      end
    end
  end

  def self.get_base_data(view)
    where(view: view)
  end

  def self.to_csv(view)
    CSV.generate do |csv|
      csv << [view.title] if view
      csv << view.column_labels
      get_base_data(view).each do |fact|
        row = []
        view.columns.each do |col|
          row << fact.send(col)
        end
        csv << row
      end
    end
  end

  def project_name
    upwp_project.name
  end

  def project_description
    upwp_project.description
  end

  def project_year
    upwp_project.year
  end

  def project_category
    upwp_project.project_category  
  end

  def project_sponsor
    upwp_project.sponsor
  end

  def project_total_staff_cost
    upwp_project.total_staff_cost
  end

  def project_budgeted_other_cost
    upwp_project.budgeted_other_cost
  end
end
