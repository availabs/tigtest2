class BpmSummaryFact < ActiveRecord::Base
  belongs_to :view
  belongs_to :area
  attr_accessible :view, :area, :count, :mode, :orig_dest, :purpose, :year

  def self.pivot?
    false
  end

  def self.exportable_as_shp?
    true
  end

  def self.styleable?
    true
  end

  def self.loadCSV(filename, view, year)
    CSV.open(filename, headers: true, return_headers: false) do |csv|
      csv.each do |row|
        area = nil
        csv.headers.each do |header|
          if header == 'taz'
            area = Area.find_by_name(row[header])
          else
            attributes = Hash.new
            attributes[:view] = view
            attributes[:year] = year
            attributes[:area] = area
            attributes.merge!(parse_header(header))
            attributes[:count] = row[header]
            BpmSummaryFact.create(attributes)
          end
        end
      end
    end
  end

  def self.parse_header header
    result = Hash.new
    result[:orig_dest] = header.slice(0, 4)
    result[:purpose] = header.include?('Non') ? 'NonWork' : 'Work'
    result[:mode] = header.slice(header.index('Work')+4, 3)

    return result
  end

  # area_type not used currently
  def self.apply_area_filter(view, area, area_type)
    if area.nil?
      includes(:area).where(view_id: view)
    elsif area.is_study_area? 
      joins(area: :base_geometry).where("ST_Intersects(?, base_geometries.geom)", area.base_geometry.try(:geom))
    else
      includes(:area)
        .where(view_id: view)
        .joins(area: :areas_enclosing)
        .where(area_enclosures: {enclosing_area_id: area})
    end
  end

end
