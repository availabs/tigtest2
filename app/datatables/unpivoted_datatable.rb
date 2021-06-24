class UnpivotedDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::SimplePaginator
  include ToCsv

  # TODO: once we have a class besides ComparativeFact, make this depend on view/model.
  def sortable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    if options[:model] == ComparativeFact
      @sortable_columns ||= ["Area.name", "Area.fips_code", "Area.fips_code", "ComparativeFact.base_value", "ComparativeFact.value",
                             "coalesce(#{options[:model_underscored]}.value / nullif(#{options[:model_underscored]}.base_value,0),0)"]
    elsif options[:model].respond_to? :sortable_searchable_columns
      @sortable_columns ||= options[:model].sortable_searchable_columns(options[:view])
    end
  end

  def searchable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    if options[:model] == ComparativeFact
      # 'percent' is a special case indicator to new_search_condition
      @searchable_columns ||= ["Area.name", "Area.name",  "Area.fips_code", "ComparativeFact.base_value", "ComparativeFact.value", "ComparativeFact.percent"]
    elsif options[:model].respond_to? :sortable_searchable_columns
      @searchable_columns ||= options[:model].sortable_searchable_columns(options[:view])
    end
  end

  def as_json(opts = {})
    json = super
    if options[:model] == CountFact

      # Special handling for TransitRoute
      @ignore_transit_route = true
      route_ids = composite_search(get_raw_records)
                  .order(:transit_mode_id, :transit_route_id)
                  .pluck(:transit_mode_id, :transit_route_id).uniq
      @ignore_transit_route = false
      current_mode_id = route_ids.first[0] if route_ids.first
      routes = []
      route_ids.each do |mode_id, route_id|
        routes << '' unless current_mode_id == mode_id # divider between modes
        routes << TransitRoute.where(id: route_id).pluck(:name).first
        current_mode_id = mode_id
      end
      json[yadcf_idx('transit_route')] = routes
      
      json[yadcf_idx('count_variable')] = CountVariable.pluck(:name)
      json[yadcf_idx('transit_mode')] = TransitMode.pluck(:name)
      json[yadcf_idx('out_station')] = json[yadcf_idx('in_station')] = TransitStation.pluck(:name)
      json[yadcf_idx('direction')] = ['Inbound', 'Outbound']
      json[yadcf_idx('location')] = Location.pluck(:name)
      json[yadcf_idx('sector')] = Sector.pluck(:name)
      json[yadcf_idx('hour')] = [0, 0]
      json[yadcf_idx('transit_agency')] = TransitAgency.pluck(:name)
      json[yadcf_idx('year')] = (CountFact.minimum(:year)..CountFact.maximum(:year)).to_a
    elsif options[:model] == RtpProject
      json[yadcf_idx('year')] = RtpProject.where.not(year: 0).order(:year).pluck(:year).uniq
      json[yadcf_idx('ptype')] = Ptype.where(id: RtpProject.select(:ptype_id).uniq).order(:name).pluck(:name).reject(&:blank?)
      json[yadcf_idx('plan_portion')] = PlanPortion.where(id: RtpProject.select(:plan_portion_id).uniq).order(:name).pluck(:name).reject(&:blank?)
      rtp_sponsors = RtpProject.select(:sponsor_id)
      if options[:view]
        rtp_sponsors = rtp_sponsors.where(view: options[:view])
      end

      json[yadcf_idx('sponsor')] = Sponsor.where(id: rtp_sponsors.uniq.pluck(:sponsor_id)).order(:name).pluck(:name).reject(&:blank?)
      json[yadcf_idx('county')] = ['MULTI'] + Area.where(id: RtpProject.select(:county_id).uniq).order(:name).pluck(:name)

      county_idx = options[:view].columns.index('county')

      for row in json[:data]
        row[county_idx] = 'MULTI' if row[county_idx].blank?
        mapurl = Rails.application.routes.url_helpers.map_view_path(options[:view], rtp_id: row[0])
        row.push(mapurl)
      end
    elsif options[:model] == TipProject
      json[yadcf_idx('ptype')] = Ptype.where(id: TipProject.select(:ptype_id).uniq).order(:name).pluck(:name)
      json[yadcf_idx('mpo')] = Mpo.where(id: TipProject.select(:mpo_id).uniq).order(:name).pluck(:name)
      tip_sponsors = TipProject.select(:sponsor_id)
      if options[:view]
        tip_sponsors = tip_sponsors.where(view: options[:view])
      end
      json[yadcf_idx('sponsor')] = Sponsor.where(id: tip_sponsors.uniq.pluck(:sponsor_id)).order(:name).pluck(:name).compact
      json[yadcf_idx('county')] = ['MULTI'] + Area.where(id: TipProject.select(:county_id).uniq).order(:name).pluck(:name)

      county_idx = options[:view].columns.index('county')

      json[:data] = json[:data].uniq

      for row in json[:data]
        row[county_idx] = 'MULTI' if row[county_idx].blank?
        mapurl = Rails.application.routes.url_helpers.map_view_path(options[:view], tip_id: row[0])
        row.push(mapurl)
      end
    end
    json
  end

  private

  def yadcf_idx(var)
    "yadcf_data_#{options[:view].columns.index(var)}"
  end
  
  # override base
  def filter_records(records)
    records = simple_search(records)
    records = composite_search(records)
    records = range_filter(records)
    records
  end

  # override to handle yadcf quirks and other special cases
  def new_search_condition(column, value)
    model, column = column.split('.')
    model = model.constantize
    Rails.logger.debug "#{model}, #{column}, #{value}"
    # number ranges
    if value.include? '-yadcf_delim-'
      min, max = value.split('-yadcf_delim-')
      
      # For Count Fact hour filter, e.g., [1,2], would only return data with hour = 1, without hour = 2
      # this is because, the real meaning of hour in Count Fact is starting hour, it really means From 1 to 2
      if model == CountFact && column == 'hour' && max.present?
        min = min.to_i if min.present?
        max = max.to_i

        # Rule 1: return full day if min_hour == max_hour
        if max == min 
          min = 0
          max = 23
        else
          # Rule 2: take 0 (12AM) as end of day
          if max == 0
            max = 23
          else
            # Rule 3: exclude the data with hour = max_hour
            max -= 1
          end
        end
      end

      if min || max
        arel_col = model.arel_table[column.to_sym]
        cond = []
        if min
          cond << arel_col.gteq(min)
        end
        if max
          cond << arel_col.lteq(max)
        end
        cond.reduce(:and)
      end
    elsif column == 'percent'
      if value.include?('%') 
        # special case for percent columns, making assumptions here
        # also note that I'm invoking the round(v numeric, s int) form of round
        # because round(double precision) in pg 9.3.9 on heroku does round half to even
        table = model.arel_table
        return ::Arel::Nodes::NamedFunction.new('round',
                 [::Arel::Nodes::NamedFunction.new('cast',
                   [::Arel::Nodes::NamedFunction.new('coalesce',
                      [table[:value] * 100 / ::Arel::Nodes::NamedFunction.new('nullif',
                                                      [table[:base_value], 0]),
                                  0]).as('numeric')]),
                                             0]).eq(value.gsub('%','').to_i)
      end
    elsif @ignore_transit_route && (model == TransitRoute) && (column == 'name')
    # HACK: Special handling for Route column filter in Hub Bound Data. Ignore this clause.
    else

      if model == Area && column == 'name' && value == 'MULTI' && (options[:model] == TipProject || options[:model] == RtpProject)
        table = options[:model].arel_table
        table[:county_id].eq(nil)
      else
        casted_column = ::Arel::Nodes::NamedFunction.new('CAST', [model.arel_table[column.to_sym].as(typecast)])
        # deal with exact match on %
        value = value.gsub('%', '\\%')
        # exact & startsWith matches
        if value.first == '^'
          if value.last == '$' # exact
            if value == '^$'
              # special case, empty exact match search should match everything
              return
            else
              search = value[1...-1] # three dots, trim 1st and last
            end
          else #startsWith
            search = "#{value[1..-1]}%" # two dots, just trim 1st
          end
        else
          search = "%#{value}%"
        end

        return casted_column.matches(search)
      end
    end
  end

  # Assumes model has range_select
  def range_filter(records)
    model = options[:model]
    return records unless model.respond_to? :range_select
    
    lower = params[:lower]
    upper = params[:upper]

    if model == ComparativeFact
      model.range_select(records, lower, upper, options[:value_column])
    else
      model.range_select(records, lower, upper)
    end
  end

  def data
    records.map do |fact|
      record = []
      options[:view].columns.each do |col|
        record << fact.send(col).to_s
      end
      record
    end
  end

  def get_raw_records
    if options[:model].respond_to?(:apply_area_filter)
      options[:model].apply_area_filter(options[:view], options[:area], options[:area_types])
    else
      options[:model].get_base_data(options[:view])
    end
  end

  def join_enclosures(base, areas)
    base.joins(area: :areas_enclosing).where(area_enclosures: {enclosing_area_id: areas})
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
