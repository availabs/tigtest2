class Source < ActiveRecord::Base
  belongs_to :user 
  belongs_to :agency
  has_many :views
  has_many :uploads
  belongs_to :rows_updated_by, class_name: User
  has_and_belongs_to_many :contributors,
                          class_name: "User",
                          join_table: :contributors_sources
  has_and_belongs_to_many :librarians,
                          class_name: "User",
                          join_table: :librarians_sources                        
  has_many :access_controls, dependent: :destroy
  has_many :watches
  has_many :comments

  after_initialize :init

  attr_accessible(:current_version, :data_ends_at, :data_starts_at, :description, :disclaimer, :name, 
                  :origin_url, :rows_updated_at, :rows_updated_by, :source_type, 
                  :topic_area, :user_id, :user, :contributor_ids, :rows_updated_by_id, :librarian_ids, :default_data_model, :agency_id)

  validates :name, presence: true

  before_destroy :ensure_not_referenced_by_view

  def user
    super || User.default if user_id
  end

  def add_view(name)
    view = self.views.build
    view.name = name
    view.user = @user
    view.save

    return view
  end

  def data_model
    default_data_model.constantize if (default_data_model && !default_data_model.empty?)
  end

  def uploadable?
    model = data_model
    model && model.respond_to?(:source_uploadable?) && model.source_uploadable?
  end

  def upload_extensions
    model = data_model
    model && model.respond_to?(:upload_extensions) && model.upload_extensions
  end

  private

    def ensure_not_referenced_by_view 
      if views.empty?
        return true
      else
        errors.add(:base, 'Views present')
        return false
      end
    end

    def init
      self.current_version ||= 1 if self.has_attribute? :current_version
    end
end
