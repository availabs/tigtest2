class StudyArea < Area 
  belongs_to :user
  has_and_belongs_to_many :viewers,
                          class_name: "User",
                          join_table: :viewers_study_areas

  validates :user, presence: true
  validates :base_geometry, presence: true
  
  default_scope { where(type: 'study_area') }

  attr_accessible :name, :type, :description, :user_id, :base_geometry, :published, :viewer_ids

  def self.viewable_by(user)
    if user
      shared_study_areas = joins(:viewers).where(viewers_study_areas: {user_id: user.id})
      published_or_owned = where("areas.user_id = ? OR published = ?", user.id, true)
      (published_or_owned << shared_study_areas).flatten.uniq
    else
      where(published: true)
    end
  end

  def user
    super || User.default if user_id
  end
end
