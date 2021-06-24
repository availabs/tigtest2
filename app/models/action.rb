class Action < ActiveRecord::Base
  has_and_belongs_to_many :views, :join_table => :views_actions
  belongs_to :resource, :polymorphic => true
  
  scopify

  def self.all_names
    all.order(:id).collect(&:name)
  end

  def self.all_actions_filtered
    where("name != 'view_metadata' and name != 'edit_metadata'")
  end

  def self.base_actions
    all_names.delete_if { |name| !["map", "table", "chart", "watch", "view_metadata"].include?(name) }
  end

  def self.guest_actions
    all_names.delete_if { |name| !["map", "table", "chart", "view_metadata"].include?(name) }
  end

  def self.contributor_actions
    all_names.reject do |name|
      name != "view_metadata" &&
      name != "edit_metadata"
    end
  end
end
