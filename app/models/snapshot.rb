class Snapshot < ActiveRecord::Base
  belongs_to :user
  belongs_to :view
  belongs_to :area
  has_and_belongs_to_many :viewers,
                          class_name: "User",
                          join_table: :viewers_snapshots

  validates :user, presence: true
  validates :name, presence: true
  validates :view, presence: true

  serialize :filters, Hash
  serialize :table_settings, JSON
  serialize :map_settings, JSON

  # enum app: [ :table, :map, :chart, :metadata ]

  default_scope { where(view_id: View.pluck("id")) }

  def user
    super || User.default if user_id
  end
end
