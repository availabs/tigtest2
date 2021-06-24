class Column < ActiveRecord::Base
  validates :name, presence: true
  belongs_to :symbology

  def as_json
    {
      name: name,
      title: title,
      index: name
    }
  end
end
