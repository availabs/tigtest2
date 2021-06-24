class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :sources
  has_many :views
  has_many :comments, dependent: :destroy
  has_many :watches, dependent: :destroy
  has_many :uploads, dependent: :destroy
  has_many :study_areas, dependent: :destroy
  has_many :access_controls, dependent: :destroy

  has_and_belongs_to_many :contributed_sources, class_name: "Source", join_table: :contributors_sources
  has_and_belongs_to_many :contributed_views, class_name: "View", join_table: :contributors_views

  has_and_belongs_to_many :sources, join_table: :librarians_sources
  has_and_belongs_to_many :views, join_table: :librarians_views

  has_and_belongs_to_many :snapshots, join_table: :viewers_snapshots

  belongs_to :agency
  
  before_destroy :ensure_not_source_owner, :clean_up_habtms

  # Setup accessible (or protected) attributes for your model
  attr_accessible :role_ids, :as => :admin
  attr_accessible :display_name, :email, :phone, :agency_id, :password, :password_confirmation, :remember_me, :recent_activity_expanded_limit, :recent_activity_dashboard_limit, :edited_user, :snapshot_limit

  validates :recent_activity_expanded_limit, :numericality => {:only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 100}
  validates :recent_activity_dashboard_limit, :numericality => {:only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 100}
  validates :snapshot_limit, :numericality => {:only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 100}

  def self.default
    @default = @default || User.new(email: 'Deleted User', display_name: 'Deleted User')
    @default
  end
  
  private 

  def ensure_not_source_owner
    if sources.empty?
      return true
    else
      errors.add(:base, 'User owns at least one Source')
      return false
    end
  end

  def clean_up_habtms
    snapshots.clear
    contributed_sources.clear
    contributed_views.clear
    views.clear
    sources.clear
  end
end
