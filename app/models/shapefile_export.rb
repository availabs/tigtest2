class ShapefileExport < ActiveRecord::Base
  belongs_to :view
  belongs_to :user
  belongs_to :tmp_shapefile, dependent: :destroy
  belongs_to :delayed_job, class_name: Delayed::Job.class.name

  validates_presence_of :view

  def user
    super || User.default if user_id
  end
end
