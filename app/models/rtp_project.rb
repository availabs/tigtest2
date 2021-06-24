class RtpProject < ActiveRecord::Base
  belongs_to :view
  belongs_to :plan_portion
  belongs_to :infrastructure #deprecated
  belongs_to :project_category #deprecated
  belongs_to :sponsor
  belongs_to :ptype
  belongs_to :county, class_name: "Area"
  attr_accessible :view, :plan_portion, :infrastructure, :project_category, :sponsor, :ptype, :county
  attr_accessible :description, :estimated_cost, :geography, :rtp_id, :year,

  def self.pivot?
    false
  end
  
  # TODO: this looks like deprecated/outdated
  def self.loadCSV(filename, view)
    CSV.open(filename, headers: true, return_headers: false) do |csv|
      csv.each do |row|
        attributes = Hash.new
        attributes[:view] = view
        csv.headers.each do |header|
          if header != 'Ignore'
            begin
              string = row[header]
              string = string.titleize unless header == 'Sponsor'
              value = getDimension(header, string)
            rescue NameError
              if header == 'County'
                value = Area.where(name: row[header].try(:titleize), type: 'county').first
              elsif header == 'EstimatedCost'
                value = row[header] ? row[header][ /\d+(?:\.\d+)?/ ] : nil
              else
                value = row[header]
              end
            end
            attributes[header.underscore] = value
          end
        end
        RtpProject.create(attributes)
      end

    end

  end

  def self.loadShp(filename, view)
    good_count = 0
    bad_count = 0
    begin
      factory = RGeo::Geographic.spherical_factory(:srid => 4326)
      RGeo::Shapefile::Reader.open(filename, :factory => factory) do |file|
        file.each do |record|
          attributes = Hash.new
          attributes[:view] = view
          attributes[:geography] = record.geometry.try(:as_text)
          attributes[:plan_portion] = PlanPortion.where(name: record['Vision_Con'].try(:titleize)).first_or_create
          attributes[:sponsor] = Sponsor.where(name:record['Sponsor']).first_or_create

          ptype = record['PTYPE']
          case ptype
          when 'PED'
            ptype_name = 'Pedestrian'
          when 'ITS'
            ptype_name = 'ITS'
          else
            ptype_name = ptype.try(:titleize)
          end
          attributes[:ptype] = Ptype.where(name: ptype_name).first_or_create

          attributes[:county] = Area.where(name: record['County'].try(:titleize), type: :county).first

          attributes[:rtp_id] = record['RTP_ID_201']
          attributes[:description] = record['Project']
          attributes[:year] = record['ProjYear']
          attributes[:estimated_cost] = record['EstCost'] ? record['EstCost'][ /\d+(?:\.\d+)?/ ] : nil

          RtpProject.new(attributes).save ? good_count+=1 : bad_count+=1     
        end
      end
    rescue Exception => e
      puts e.message
    end

    puts "imported #{good_count} projects from #{filename}; #{bad_count} failed."

  end

  def self.getDimension(dimension, name)
    dimClass = dimension.constantize
    dimClass.find_or_create_by( name: name )
  end
  
  def self.apply_area_filter(view, area, area_type)
    # don't use area_type directly but use it to determine how to filter by area
    base = includes(:county, :plan_portion, :sponsor, :ptype)
               .references(:county, :plan_portion, :sponsor, :ptype)
      .where(view_id: view)
    if area.nil?
      return base
    elsif area.type == 'county'
      return base.where(county_id: area)
    else
      return base.joins(county: :areas_enclosing)
        .where(area_enclosures: {enclosing_area_id: area})
    end
  end

  def self.to_csv(view)
    CSV.generate do |csv|
      csv << [view.title] if view
      csv << view.columns.collect {|c| c.titleize}
      apply_area_filter(view, nil, nil).each do |fact|
        row = []
        view.columns.each do |col|
          row << fact.send(col)
        end
        csv << row
      end
    end
  end

  def self.sortable_searchable_columns(view)
    view.columns.collect do |col|
      case col
      when 'rtp_id', 'description', 'year', 'estimated_cost'
        "RtpProject.#{col}"
      when 'county'
        "Area.name"
      else
        "#{col.camelize}.name"
      end
    end
  end

  # Select facts where percent is >= lower and < upper
  # Assumes facts all have same view
  def self.range_select(facts, lower, upper)
    if lower.blank? && upper.blank?
      facts
    else
      unless lower.blank?
        lower = lower.to_f
        facts = facts.where('count >= ?', lower)
      end
      unless upper.blank?
        upper = upper.to_f
        facts = facts.where('count <= ?', upper)
      end
      facts
    end
  end

  def self.get_data(view_id, ptype, sponsor, plan_portion, year, cost_lower, cost_upper, area, rtp_id)

    query_hash = {}

    if !view_id.blank?
      query_hash[:view_id] = view_id.to_i
    end
    if !ptype.blank?
      query_hash[:ptype] = ptype.to_i
    end
    if !sponsor.blank?
      query_hash[:sponsor] = sponsor.to_i
    end
      
    if !plan_portion.blank?
      query_hash[:plan_portion] = plan_portion.to_i
    end
    if !year.blank?
      query_hash[:year] = year
    end
    if !cost_lower.blank? || !cost_upper.blank?
      if cost_lower.blank?
        cost_lower = 0;
      end
      if cost_upper.blank?
        cost_upper = Float::INFINITY;
      end
      query_hash[:estimated_cost] = cost_lower.to_f..cost_upper.to_f
    end
    base = includes(:ptype, :sponsor, :county, :plan_portion).where(query_hash)
    if !area.nil?
      if area.is_county?
        base = base.joins(county: :areas_enclosing).where(county_id: area)
      elsif area.is_study_area?
        base = base.where("ST_Intersects(?, ST_GeomFromText(rtp_projects.geography, 4326))", area.base_geometry.try(:geom))
      else
        base = base.joins(county: :areas_enclosing).where(area_enclosures: {enclosing_area_id: area})
      end
    end
    # allow partial matches on rtp_id
    if !rtp_id.blank?
      base = base.where(arel_table[:rtp_id].matches("%#{rtp_id}%"))
    end
    
    base
  end

  def self.exportable_as_shp?
    true
  end

  def self.configure_default_columns(view)
    view.columns = ["rtp_id", "description", "year", "estimated_cost", "ptype", "plan_portion", "sponsor", "county"]
    view.column_labels = ["RTP ID", "Description", "Year", "Estimated Cost", "Project Type", "Plan Portion", "Sponsor", "County"]
    view.column_types = ["", "", "", "millions", "", "", "", ""]
    view.data_levels = ['Project']

    view.save(validate: false)
  end

  def self.upload_extensions
    'zip'
  end

  def self.process_upload(io, view, year, month, extension, &block)
    return unless extension == '.zip'

    # Clear existing facts
    yield('deleting') if block_given?
    where(view: view).delete_all
    
    processZip(io, view, &block)
  end

  def self.processZip(io, view)
    yield('parsing shapefiles') if block_given?
    dest_dir = ZipFileGenerator.new(io.path).unzip_file_to_dir
    Dir.entries(dest_dir).each do |entry|
      next unless File.extname(entry) == '.shp'
      yield("parsing #{entry}") if block_given?
      self.loadShp(File.join(dest_dir, entry), view)
      yield('count', where(view: view).count) if block_given?
    end
    yield('processed') if block_given?
  end

end
