# by default, demographic_fact is assigned with quantile breaks color scheme

class DemographicFactSymbologyService < ViewSymbologyService

  DEFAULT_BREAK_COUNT = 8

  # create default symbology
  def configure_symbology
    return nil if !@view

    puts "starting demo fact view #{@view.name} symbology config"

    area_type = Area.parse_area_type(@view.data_levels[0])

    symbology_params = {
      is_default: true,
      view: @view,
      symbology_type: Symbology::QUANTILE_BREAKS,
      subject: @view.statistic.caption,
      number_formatter: NumberFormatter.where(format_type: 'number', options: {
        format: '#,##0', 
        locale: 'us'
        }.to_json).first_or_create
    }

    symbology_params = case @view.statistic.name
    when 'Population'
      get_symbology_configs_for_population(symbology_params, area_type)
    when 'TAZ Population'
      get_symbology_configs_for_population(symbology_params, Area::AREA_LEVELS[:taz])
    when 'School Enrollment'
      get_symbology_configs_for_school_enrollment(symbology_params, area_type)
    when 'Employment'
      get_symbology_configs_for_employment(symbology_params, area_type)
    when 'Household Income'
      get_symbology_configs_for_household_income(symbology_params, area_type)
    else
      symbology_params
    end 

    # create symbology instance
    symbology = Symbology.where(symbology_params).first_or_create

    puts "symbology created: #{symbology.id}"

    # assign columns and default column
    assign_default_demo_fact_columns(symbology, area_type)

    puts "columns assigned: #{symbology.columns.count}"

    # configure color scheme
    color_scheme_params = {
      symbology: symbology,
      start_color: "yellow",
      end_color: "red",
      class_count: 5
    }

    color_scheme = QuantileBreaksColorScheme.where(color_scheme_params).first_or_create

    puts "color scheme created: #{color_scheme.id}"
  end

  private

  # assign columns for the symbology
  def assign_default_demo_fact_columns(symbology, area_type)
    return nil unless symbology

    # create symbology associated columns
    for i in 1..(@view.columns.count - 1)
      year = @view.columns[i]
      column = Column.where({ 
        symbology: symbology,
        name: year, 
        title: get_demo_fact_year_layer_title(year, area_type, @view.statistic.caption)
      }).first_or_create

      first_column = column if i == 1
    end

    # default column
    symbology.update_attributes(default_column_index: first_column.name) if first_column
  end

  # proper titles for each year column
  def get_demo_fact_year_layer_title(year, area_type, subject)
    case subject
    when 'Population'
      if @view.value_name == :density
        "#{year} density (pers/sq mi)"
      else
        case area_type
        when Area::AREA_LEVELS[:county]
          "#{year} population (000)"
        when Area::AREA_LEVELS[:taz]
          "#{year} population"
        else
          # no match title template
          ''
        end
      end
    when 'TAZ Population'
      if @view.value_name == :density
        "#{year} density (pers/sq mi)"
      else
        "#{year} population"
      end
    when 'School Enrollment'
      "#{year} school enrollment"
    when 'Employment'
      "#{year} employment"
    when 'Household Income'
      "#{year} avg. household income ($)"
    else
      "#{year} #{subject.downcase}"
    end
  end

  # find out symbology configs for each statistic
  def get_symbology_configs_for_population(base_configs, area_type) 
    base_configs = base_configs || {}
    if @view.value_name == :density
      base_configs.merge({ 
        subject: 'Density (pers/sq mi)'
      })
    else
      case area_type
      when Area::AREA_LEVELS[:county]
        base_configs.merge({ 
          subject: 'Population (000)'
        })
      when Area::AREA_LEVELS[:taz], Area::AREA_LEVELS[:census_tract]
        base_configs.merge({ 
          subject: 'Population'
        })
      else
        # no match symbology
        nil
      end
    end
  end

  def get_symbology_configs_for_school_enrollment(base_configs, area_type) 
    base_configs = base_configs || {}

    case area_type
    when Area::AREA_LEVELS[:county]
      base_configs.merge({ 
        subject: 'School Enrollment (000)'
      })
    when Area::AREA_LEVELS[:taz]
      base_configs.merge({ 
        subject: 'School Enrollment'
      })
    else
      # no match symbology
      nil
    end
  end

  def get_symbology_configs_for_employment(base_configs, area_type) 
    base_configs = base_configs || {}

    case area_type
    when Area::AREA_LEVELS[:county]
      base_configs.merge({ 
        subject: 'Employment (000)'
      })
    when Area::AREA_LEVELS[:taz]
      base_configs.merge({ 
        subject: 'Employment'
      })
    else
      # no match symbology
      nil
    end
  end

  def get_symbology_configs_for_household_income(base_configs, area_type) 
    base_configs = base_configs || {}
    formatter_currency = NumberFormatter.where(format_type: 'currency', options: {
      format: '#,##0', 
      locale: 'us'
      }.to_json).first_or_create

    case area_type
    when Area::AREA_LEVELS[:county]
      base_configs.merge({ 
        subject: 'Average Household Income ($/1000)',
        number_formatter: formatter_currency
      })
    when Area::AREA_LEVELS[:taz]
      base_configs.merge({ 
        subject: 'Average Household Income ($)',
        number_formatter: formatter_currency
      })
    else
      # no match symbology
      nil
    end
  end

  # find configurations for the default geometric breaks color scheme
  def get_default_geometric_breaks_color_scheme(base_configs)
    base_configs = base_configs || {}
    exact_break = DemographicFact.where(view: @view).maximum(:value) / DEFAULT_BREAK_COUNT
    # round to a single significant digit
    break_value = exact_break.round(-1*(exact_break.to_int.to_s.length - 1))
    base_configs.merge({
      gap_value: break_value
    })
  end

  def get_geometric_breaks_color_scheme_for_population(base_configs, area_type) 
    base_configs = base_configs || {}
    if @view.value_name == :density
      case area_type
      when Area::AREA_LEVELS[:county]
        base_configs.merge({ 
          gap_value: 1000,
          multiplier: 2
        })
      when Area::AREA_LEVELS[:taz]
        base_configs.merge({ 
          gap_value: 1000,
          multiplier: 3
        })
      else
        nil
      end
    else
      case area_type
      when Area::AREA_LEVELS[:county]
        base_configs.merge({ 
          gap_value: 400
        })
      when Area::AREA_LEVELS[:taz]
        base_configs.merge({ 
          gap_value: 20000
        })
      when Area::AREA_LEVELS[:census_tract]
        base_configs.merge({ 
          gap_value: 1000
        })
      else
        # no match symbology
        nil
      end
    end
  end

  def get_geometric_breaks_color_scheme_for_school_enrollment(base_configs, area_type) 
    base_configs = base_configs || {}

    case area_type
    when Area::AREA_LEVELS[:county]
      base_configs.merge({ 
        gap_value: 100
      })
    when Area::AREA_LEVELS[:taz]
      base_configs.merge({ 
        gap_value: 6000
      })
    else
      # no match symbology
      nil
    end
  end

  def get_geometric_breaks_color_scheme_for_employment(base_configs, area_type) 
    base_configs = base_configs || {}

    case area_type
    when Area::AREA_LEVELS[:county]
      base_configs.merge({ 
        gap_value: 200
      })
    when Area::AREA_LEVELS[:taz]
      base_configs.merge({ 
        gap_value: 10000
      })
    else
      # no match symbology
      nil
    end
  end

  def get_geometric_breaks_color_scheme_for_household_income(base_configs, area_type) 
    base_configs = base_configs || {}

    case area_type
    when Area::AREA_LEVELS[:county]
      base_configs.merge({ 
        gap_value: 200
      })
    when Area::AREA_LEVELS[:taz]
      base_configs.merge({ 
        gap_value: 200000
      })
    else
      # no match symbology
      nil
    end
  end

end