class ProjectCategory < ActiveRecord::Base
  attr_accessible :name
  extend NamedValue
  include DisplayName
end
