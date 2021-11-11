class TipProject < ActiveRecord::Base
  belongs_to :view
  belongs_to :ptype
  belongs_to :mpo
  belongs_to :sponsor
  belongs_to :county, class_name: "Area"

  def self.pivot?
    false
  end

    def self.loadShp(filename, view)
    good_count = 0
    bad_count = 0
    begin
      factory = RGeo::Geographic.spherical_factory(:srid => 4326)
      RGeo::Shapefile::Reader.open(filename, :factory => factory) do |file|
        # Figure out what version of each key to use
        mpopin_key = file[0].keys.detect {|k| k.downcase.strip == 'mpopin'}
        yield("mpopin_key #{mpopin_key} keys #{file[0].keys.to_s}") if block_given?
        Delayed::Worker.logger.info("mpopin_key #{mpopin_key} keys #{file[0].keys.to_s}" )
        cost_key = file[0].keys.detect do |k|
          k = k.downcase.strip
          k == 'cost' || k == 'projcost'
        end

        sponsor_key = file[0].keys.detect do |k|
          k = k.downcase.strip
          k == 'agency' || k == 'respagency' || k == 'respagncy'
        end

        desc_key = file[0].keys.detect {|k| k.downcase.strip == 'lgdesc'}

        mponame_key = file[0].keys.detect do |k|
          k = k.downcase.strip
          k == 'mponame'
        end

        county_key = file[0].keys.detect do |k|
          k = k.downcase.strip
          k == 'county'
        end

        file.each do |record|
          Delayed::Worker.logger.info("record for each file" )
          attributes = Hash.new
          attributes[:view] = view
          attributes[:geography] = record.geometry.try(:as_text)

          attributes[:tip_id] = record[mpopin_key]
          Delayed::Worker.logger.info("record #{record[mpopin_key]} #{mpopin_key}" )

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

          # attributes[:cost] = record[cost_key][ /\d+(?:\.\d+)?/ ] if record[cost_key]
          if record[cost_key]
            if record[cost_key].respond_to?('[]') # If record[cost_key] is a string
              attributes[:cost] = record[cost_key][ /\d+(?:\.\d+)?/ ] # get only the digits
            else
              attributes[:cost] = record[cost_key]
            end
          end
          attributes[:mpo] = Mpo.where(name: record[mponame_key]).first_or_create
          attributes[:county] = Area.where(name: record[county_key].try(:titleize), type: :county).first
          attributes[:sponsor] = Sponsor.where(name: record[sponsor_key]).first_or_create
          attributes[:description] = record[desc_key]


          TipProject.new(attributes).save ? good_count+=1 : bad_count+=1
        end
      end
    rescue Exception => e
      puts e.message
    end

    puts "imported #{good_count} projects; #{bad_count} failed."

  end

  def self.apply_area_filter(view, area, area_type)
    # don't use area_type directly but use it to determine how to filter by area
    base = includes(:county, :sponsor, :ptype, :mpo)
               .references(:county, :sponsor, :ptype, :mpo)
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

  def self.get_data(view_id, ptype, mpo, sponsor, cost_lower, cost_upper, area, tip_id)

      query_hash = {}
      if !view_id.blank?
        query_hash[:view_id] = view_id.to_i
      end
      if !ptype.blank?
        query_hash[:ptype] = ptype.to_i
      end
      if !mpo.blank?
        query_hash[:mpo] = mpo.to_i
      end
      if !sponsor.blank?
        query_hash[:sponsor] = sponsor.to_i
      end
      if !cost_lower.blank? || !cost_upper.blank?
        if cost_lower.blank?
          cost_lower = 0;
        end
        if cost_upper.blank?
          cost_upper = Float::INFINITY;
        end
        query_hash[:cost] = cost_lower.to_f..cost_upper.to_f
      end

      base = includes(:ptype, :mpo, :sponsor, :county).where(query_hash)
      if !area.nil?
        if area.is_county?
          base = base.joins(county: :areas_enclosing).where(county_id: area)
        elsif area.is_study_area?
          base = base.where("ST_Intersects(?, ST_GeomFromText(tip_projects.geography, 4326))", area.base_geometry.try(:geom))
        else
          base = base.joins(county: :areas_enclosing).where(area_enclosures: {enclosing_area_id: area})
        end
      else

      end
    # allow partial matches on tip_id
    if !tip_id.blank?
      base = base.where(arel_table[:tip_id].matches("%#{tip_id}%"))
    end

    base
  end

  def self.sortable_searchable_columns(view)
    view.columns.collect do |col|
      case col
      when 'tip_id', 'cost', 'description'
        "TipProject.#{col}"
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

  def self.exportable_as_shp?
    true
  end

  def self.configure_default_columns(view)
    view.columns = ["tip_id", "ptype", "cost", "mpo", "county", "sponsor", "description"]
    view.column_labels = ["TIP ID", "Project Type", "Cost", "MPO Name", "County", "Agency", "Description"]
    view.column_types = ["", "", "millions", "", "", "", ""]
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
    Delayed::Worker.logger.debug("process ZIp : #{io.path}")
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
