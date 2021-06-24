class NumberFormatter < ActiveRecord::Base
  validates_presence_of :format_type
  has_many :symbologies

  def as_json
    {
      format: format_type,
      options: eval(options) || {}
    }
  end
end
