class UpwpProject < ActiveRecord::Base
  belongs_to :project_category
  belongs_to :sponsor
  belongs_to :view

  has_many :upwp_related_contracts
  
  def self.pivot?
    false
  end

  def self.sortable_searchable_columns(view)
    view.columns.collect do |col|
      case col
      when :project_category, :sponsor
        "#{col.to_s.camelize}.name"
      else
        "UpwpProject.#{col}"
      end
    end
  end

  def self.get_base_data(view)
    includes(:project_category, :sponsor)
      .references(:project_category, :sponsor)
      .where(view: view)
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

  def to_s
    project_id.to_s
  end
end
