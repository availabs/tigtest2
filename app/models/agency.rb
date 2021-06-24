class Agency < ActiveRecord::Base
  has_many :users, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :access_controls, dependent: :destroy
  validates :name, presence: true
  attr_accessible :name, :description, :url, :user_ids
end
