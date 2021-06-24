require 'securerandom'
class Upload < ActiveRecord::Base
  belongs_to :view
  belongs_to :source
  belongs_to :user
  belongs_to :delayed_job, class_name: Delayed::Job
  
  attr_accessible(:filename, :s3_location, :year, :to_year, :month, :data_level, :geometry_version, :notes, :view_id, :source_id, :size_in_bytes, :user_id)

  enum status: [
         :unavailable,
         :available,
         :queued,
         :processing,
         :processed,
         :error,
         :help_doc,
         :help_html
       ]

  validate :require_view_or_source_presence
  validates_presence_of :month, if: Proc.new { view && view.facts_have_month? }
  validates_presence_of :year, unless: Proc.new { view.blank? || [RtpProject, TipProject, ComparativeFact].include?(view.data_model) }
  validate :has_file

  BASE_STORAGE_DIR = "#{Rails.root}/public"

  def user
    super || User.default if user_id
  end

  # get the local storage dir
  # create the dir if not exists
  def local_storage_dir
    "#{BASE_STORAGE_DIR}/#{local_storage_path}"
  end

  def local_storage_url
    "#{local_storage_path}/#{filename}"
  end

  def public_path
    if s3_location.to_s.starts_with?('uploads')
      "#{BASE_STORAGE_DIR}/#{s3_location}"
    else
      s3_location
    end
  end

  private

  def require_view_or_source_presence
    if status != 'help_doc' && status != 'help_html' && !(view || source)
      errors.add(:base, "must be associated with a view or a source")
    end
  end

  def has_file
    if s3_location.blank? || filename.blank?
      errors.add(:base, 'Please select a file to upload.')
    end
  end

  def local_storage_path
    category = if source.present?
      "source/#{source.id}"
    elsif view.present?
      "view/#{view.id}"
    else
      'other'
    end

    "uploads/#{category}/#{random_id}"
  end

  def random_id
    @random_id ||= SecureRandom.urlsafe_base64
  end

end
