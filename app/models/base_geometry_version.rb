class BaseGeometryVersion < ActiveRecord::Base
  def self.versions(category)
    where(category: category).pluck(:version)
  end
end
