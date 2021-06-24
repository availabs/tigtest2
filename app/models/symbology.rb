class Symbology < ActiveRecord::Base
  validates :subject, presence: true

  default_scope { order("is_default desc", :subject) }
  
  belongs_to :number_formatter
  belongs_to :view

  has_many :columns, :dependent => :destroy

  has_one :quantile_breaks_color_scheme, :dependent => :destroy
  has_one :natural_breaks_color_scheme, :dependent => :destroy
  has_one :geometric_breaks_color_scheme, :dependent => :destroy
  has_many :custom_breaks_color_schemes, :dependent => :destroy
  has_many :unique_value_color_schemes, :dependent => :destroy


  # types
  QUANTILE_BREAKS = :quantile_breaks
  NATURAL_BREAKS = :natural_breaks
  GEOMETRIC_BREAKS = :geometric_breaks
  CUSTOM_BREAKS = :custom_breaks
  UNIQUE_VALUE = :unique_value

  def as_json(default_column_name = nil)
    # base
    base_configs = {
      id: id,
      subject: subject,
      show_legend: show_legend,
      symbology_type: symbology_type,
      columns: []
    }
    if number_formatter
      base_configs[:number_formatter] = number_formatter.as_json
    end

    # columns
    asssociated_columns = get_associated_columns
    default_column_index = asssociated_columns.first.name if asssociated_columns
    default_column_name = default_column_name.to_s if default_column_name
    asssociated_columns.each do | column |
      base_configs[:columns] << column.as_json
      default_column_index = column.name if column.name == default_column_name
    end

    base_configs[:default_column_index] = default_column_index if default_column_index

    # color scheme
    base_configs[:color_scheme] = case symbology_type.to_sym
    when QUANTILE_BREAKS
      quantile_breaks_color_scheme.as_json if quantile_breaks_color_scheme
    when NATURAL_BREAKS
      natural_breaks_color_scheme.as_json if natural_breaks_color_scheme
    when GEOMETRIC_BREAKS
      geometric_breaks_color_scheme.as_json if geometric_breaks_color_scheme
    when CUSTOM_BREAKS
      custom_breaks_color_schemes.order(:label, :min_value, :max_value).as_json
    when UNIQUE_VALUE
      unique_value_color_schemes.order(:label, :value).as_json
    end

    base_configs
  end

  def editable_by?(user)
    user && view && ( user.has_role?(:admin) ||
      (user.has_role?(:agency_admin) && (view.source.agency == user.agency)) ||
      view.librarians.include?(user) ||
      view.contributors.include?(user) )
  end

  def base_symbology
    Symbology.find_by_id base_symbology_id
  end

  # if this symbology is created from a base_symbology, then get columns from there
  def get_associated_columns
    base_symbology_id && base_symbology ? base_symbology.columns : columns
  end

  def get_clone(new_subject, new_color_schemes)
    new_sym = self.dup
    new_sym.base_symbology_id = self.base_symbology_id || self.id
    new_sym.is_default = false
    new_sym.subject = new_subject

    case new_sym.symbology_type.to_sym
    when QUANTILE_BREAKS
      new_sym.quantile_breaks_color_scheme = QuantileBreaksColorScheme.new(new_color_schemes)
    when NATURAL_BREAKS
      new_sym.natural_breaks_color_scheme  = NaturalBreaksColorScheme.new(new_color_schemes)
    when GEOMETRIC_BREAKS
      new_sym.geometric_breaks_color_scheme = GeometricBreaksColorScheme.new(new_color_schemes)
    when CUSTOM_BREAKS
      new_color_schemes.each do |color_scheme|
        new_sym.custom_breaks_color_schemes.new(color_scheme)
      end
    when UNIQUE_VALUE
      new_color_schemes.each do |color_scheme|
        new_sym.unique_value_color_schemes.new(color_scheme)
      end
    end

    new_sym
  end

  def self.get_default
    where(is_default: true).first || self.first
  end

end
