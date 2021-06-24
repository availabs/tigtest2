class TmpShapefile < ActiveRecord::Base
  has_one :shapefile_export

  def fetch_data
    Base64.decode64 data
  end

end
