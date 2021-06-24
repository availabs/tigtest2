# require all fact models as data_model deserialize of class fails if that class is not loaded
Rails.application.config.data_models.each {|m| require m}

# for som reason the app doesn't find this model if you don't print it here
# maybe a cache thing ? 
print CountFact

class View < ActiveRecord::Base
  serialize :columns, Array
  serialize :data_model # *Fact class, *Project class
  serialize :column_types, Array
  serialize :data_levels, Array # now spatial_level
  serialize :column_labels, Array
  serialize :spatial_level
  serialize :data_hierarchy
  serialize :value_columns, Array # Intended for views has multiple value/measure columns, 
                                  # e.g. ACS has :value, :percent
                                  # BPM has :vehicle_miles_traveled, :vehicle_hours_traveled, :avg_speed
                                  # although I wonder if better to have one value/measure in each view...
  
  
  rolify :role_cname => 'Action'
  belongs_to :source
  belongs_to :user
  belongs_to :rows_updated_by, class_name: User
  belongs_to :statistic
  has_and_belongs_to_many :contributors,
                          class_name: "User",
                          join_table: :contributors_views
  has_and_belongs_to_many :librarians,
                          class_name: "User",
                          join_table: :librarians_views

  has_many :symbologies, dependent: :destroy
  has_many :access_controls, dependent: :destroy
  has_many :watches
  has_many :uploads
  has_many :comments
  has_many :snapshots

  validates :name, presence: true
  validates :data_model, presence: true
  
  after_initialize :init

  NULLIFY = [:column_name, :row_name]
  before_save :nil_if_blank
  
  attr_accessible(:columns, :data_model, :current_version, :data_ends_at, :data_starts_at,
                  :description, :column_labels, :column_types, :value_columns, :data_levels, :value_name,
                  :download_count, :last_displayed_at, :name, :origin_url, :rows_updated_at, 
                  :rows_updated_by, :rows_updated_by_id, :source_id, :statistic_id,
                  :topic_area, :user, :view_count, :data, :column_name, :row_name, :contributor_ids, :user_id, :role_ids,
                  :spatial_level, :data_hierarchy, :librarian_ids, :download_instructions)

  alias_method :has_action?, :has_role?

  default_scope { where(deleted_at: nil) }

  def user
    super || User.default if user_id
  end

  # Alias for add_role that also checks that the action has been defined.
  def add_action action
    if Action.all_names.include? action.to_s
      add_role action
    else
      raise ArgumentError, "Can not add #{action}. Only existing actions are allowed to be added"
    end
  end

  def actions
    roles.order(:id).collect(&:name)
  end

  def caption
    if statistic
      statistic.caption
    else
      description
    end
  end

  def display_name
    "#{name} (v#{current_version})"
  end

  # Stored as "string", accessed as :symbol
  def value_name
    super.to_s.to_sym
  end

  # Stored as "string", accessed as :symbol
  def column_name
    super.to_sym if super
  end

    # Stored as "string", accessed as :symbol
  def row_name
    super.to_sym if super
  end

  def facts_have_month?
    data_model.respond_to?(:facts_have_month?) && data_model.facts_have_month?
  end

  def upload_extensions
    data_model.respond_to?(:upload_extensions) && data_model.upload_extensions
  end
  
  def data
  end

  def data=(value)
  end

  # Support for "dynamic" columns
  def columns
    data_model.respond_to?(:dynamic_columns) ? data_model.dynamic_columns : super
  end
  
  def column_labels
    data_model.respond_to?(:dynamic_column_labels) ? data_model.dynamic_column_labels : super
  end
  
  def column_types
    data_model.respond_to?(:dynamic_column_types) ? data_model.dynamic_column_types : super
  end

  # intended for value_columns to find their label
  # noticed, columns[] doesn't necessarily have value_column, in this case, just return column name
  def column_label(column_name)
    column_name = column_name.to_s
    col_index = columns.index(column_name)
    col_label = column_labels[col_index] if col_index

    col_label || column_name
  end

  def reset_default_symbologies
    symbologies.destroy_all

    set_default_symbologies
  end

  def set_default_symbologies
     "#{self.data_model}SymbologyService".constantize.new(self).configure_symbology rescue nil
  end

  def symbologies_for_column(column_name)
    if !column_name.blank?
      base_sym_ids = symbologies.joins(:columns).where("columns.name = ?", column_name).pluck(:id)
      symbologies.where("id in (?) or base_symbology_id in (?)", base_sym_ids, base_sym_ids)
    else
      symbologies
    end
  end

  def title
    if data_model == ComparativeFact
      name
    else
      view_caption = caption
      if value_name == :density
        stat = statistic
        view_caption = stat.name if stat
        view_caption += " Density (persons/sq. mile)"
      end

      "#{name} : #{view_caption}"
    end
  end
  
  private

    def init
      default :current_version, 1
      default :download_count, 0
      default :view_count, 0
      default :value_name, :value
      self[:data_levels] = ["", ""] if self[:data_levels].nil? || self[:data_levels].empty?
      self[:value_columns] = ['value'] if self[:value_columns].nil? || self[:value_columns].empty?
    end

    def default field, value
      self[field] ||= value if self.has_attribute? field
    end

    def nil_if_blank
      NULLIFY.each {|a| self[a] = nil if self[a].blank?}
    end
end
