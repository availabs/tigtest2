# TAZ in Rails App

## app/models/

### app/models/area.rb

```ruby
class Area < ActiveRecord::Base

  # Area level constants
  AREA_LEVELS = {
    region: 'region',
    subregion: 'subregion',
    tcc: 'tcc',
    county: 'county',
    census_tract: 'census_tract',
    taz: 'taz'
  }

  AREA_LEVEL_DISPLAY = {
    region: 'Region',
    subregion: 'Sub Region',
    tcc: 'TCC',
    county: 'County',
    census_tract: 'Census Tract',
    taz: 'TAZ'
  }

  scope :regions, -> { where(type: AREA_LEVELS[:region]) }
  scope :subregions, -> { where(type: AREA_LEVELS[:subregion]) }
  scope :tccs, -> { where(type: AREA_LEVELS[:tcc]) }
  scope :counties, -> { where(type: AREA_LEVELS[:county]) }
  scope :census_tracts, -> { where(type: AREA_LEVELS[:census_tract]) }
  scope :tazs, -> { where(type: AREA_LEVELS[:taz]) }

  def self.is_versioned?(area_type)
    [:taz, :census_tract].index(area_type.to_sym) ? true : false
  end

  def self.years_by(type)
    Area.where(type: type).pluck(:year).uniq
  end

  def self.loadCSV(filename)
    CSV.foreach(filename, headers: true, return_headers: false) do |row|
      name = row['area']
      next if name.nil?
      area = Area.find_or_create_by( name: name.titleize )
      size = row['size']
      area.update_attributes(size: size.to_f) if size
    end

  end

  def self.convertJson2Csv(jsonFile, csvFile)
    json = JSON.parse(File.read(jsonFile))

    CSV.open(csvFile, 'wb') do |csv|
      row = Array.new(2)
      json['features'].each do |feature|
        prop = feature['properties']
        row[0] = prop['TAZ_ID']
        row[1] = prop['AREA']

        csv << row
      end
    end
    true
  end
```

### app/models/demographic_fact.rb

NOTE: ActiveRecord#update_attribute writes to the database.
See [docs](https://api.rubyonrails.org/v5.2.4.1/classes/ActiveRecord/Persistence.html#method-i-update_attribute).

```ruby
class DemographicFact < ActiveRecord::Base
  extend AggregateableFact

  belongs_to :view
  belongs_to :area
  belongs_to :statistic
  attr_accessible :value, :year

  # each uploaded file should have following view columns
  # prefix{YEAR} column represents each year's data for a given view
  SOURCE_UPLOAD_TAZ_VIEW_SETS ||= {
    :school_enrollment => {prefix: 'EnrolK12_', desc: ''},
    :total_population => {prefix: 'PopTot', desc: 'Household population plus group quarter population'},
    :total_employment => {prefix: 'EmpTot', desc: 'CTPP based'},
    :household_income => {prefix: 'HHInc', desc: 'Average household income'},
    :household_population => {prefix: 'PopHH', desc: 'Population just in households'},
    :group_quarters_population => {prefix: 'PopGQ', desc: 'Institutional GQ + Homeless GQ + Other GQ population'},
    :group_quarters_institutional_population => {prefix: 'PopGQInst', desc: ''},
    :group_quarters_homeless_population => {prefix: 'PopGQHmls', desc: ''},
    :group_quarters_other_population => {prefix: 'PopGQOth', desc: 'Colleges, universities, military, etc.'},
    :households => {prefix: 'Households', desc: 'Number of households'},
    :household_size => {prefix: 'HHSize', desc: 'Average household size', precision: 2},
    :employed_labor_force => {prefix: 'EmpLF', desc: 'Employed Civilian Labor Force'},
    :retail_employment => {prefix: 'EmpRet', desc: 'CTPP based, NAICS: 44-45'},
    :office_employment => {prefix: 'EmpOff', desc: 'CTPP based, NAICS: 51-56'},
    :earnings => {prefix: 'Earn', desc: 'Earnings per worker'},
    :university_enrollment => {prefix: 'EnrolUniv', desc: ''},
  }

  # ...

  def self.process_source_upload(io, source, from_year, to_year, geometry_base_year, data_level_text, extension, &block)
    # ...
    if data_level == :taz
      prepare_taz_uploading(source, io, from_year, to_year, geometry_base_year, &block)
    # ...
    end
  end

  # ...

  def self.prepare_taz_uploading(source, file_path, from_year, to_year, geometry_base_year, &block)
    Delayed::Worker.logger.debug('prepare_taz_uploading')
    data_level = :taz

    data_hierarchy = [["taz", "county", ["subregion", "region"]]]

    view_template = {
          :actions => [:table, :map, :chart, :view_metadata, :edit_metadata],
          :options => {
            geometry_base_year: geometry_base_year,
            data_hierarchy: data_hierarchy,
            data_starts_at: DateTime.new(from_year),
            data_ends_at: DateTime.new(to_year),
            rows_updated_at: DateTime.now,
            data_levels: [Area::AREA_LEVELS[data_level]],
            topic_area: "Demographics",
            columns: ['area'].concat(from_year.step(to_year, 5).map { |year| year.to_s }),
            column_labels: ["TAZ"].concat(from_year.step(to_year, 5).map { |year| year.to_s }),
            column_types: [''].concat(from_year.step(to_year, 5).map { |year| 'numeric' }),
            value_name: :value
      }
    }

    # ...

    load_data_from_taz_csv(source, from_year, to_year, geometry_base_year, forecast_config, &block)
  end

  def self.load_data_from_taz_csv(source, from_year, to_year, geometry_base_year, seeds_config)
    data_level = :taz
    # ...
    file_name = seeds_config[:file_name]
    stats = seeds_config[:statistics]

    counter = 0
    stats.each_with_index do |obj, index|
      stat_config = obj[:statistic]
      if stat_config
        stat = Statistic.find_or_create_by(name: stat_config[:name])
        stat_config.each do |attr, value|
# DB write
          stat.update_attribute(attr, value)
        end
        puts 'statistic: ' + stat.name
      end

      view_config = obj[:view]
      if view_config
        # ...
        view_config_options.each do |attr, value|
# DB write
          view.update_attribute(attr, value)
        end

        # ...
        fields.each do |field_config|
          # ...
          field_data = csv_data[field_name.downcase.to_sym]
          field_data.each_with_index do |value, idx|
            # ...

            rec = DemographicFact.where(
              view: view,
              year: year,
              statistic: stat,
              area_id: area_id
            ).first_or_create

# DB write
            rec.update_attribute(:value, value.to_f.round(precision))
          end
        end
        puts "#{DemographicFact.where(view: view).count} facts"
      end
    end

  # ...

```

### app/models/bpm_summary_fact.rb

Note: No bpm_summary_facts in TIG databases.

```sh
gateway_test2=# select * from bpm_summary_facts limit 3;
 id | view_id | area_id | year | orig_dest | purpose | mode | count | created_at | updated_at
----+---------+---------+------+-----------+---------+------+-------+------------+------------
(0 rows)
```

```ruby
# Best Practices Model Performance Measures
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
            # ...
          end
        end
      end
    end
  end

  # ...

end
```

## app/controllers/

## app/controllers/views_controller.rb

```ruby
class ViewsController < ApplicationController

  def set_area_variables update_session_for_area=true
    # ...
    # Remove the lowest levels (taz, census_tract) + subregion/region if not all
    reject_list = ['taz', 'census_tract']
    reject_list += ['subregion', 'region'] unless @area.nil?
    # ...
  end

  # ...

  def get_map_config_data_for_bpm_summary_fact
    area_type = Area::AREA_LEVELS[:taz]
    {
      name: @view.name,
      data: map_data,
      referenceColumn: 'area',
      referenceLayerConfig: map_layer_config_by_area_type(area_type),
      showAreaBoundary: get_area_boundary_status,
      value_column_changed: false,
      current_value_column: @current_value_column,
      symbologies: @view.symbologies.as_json
    }
  end

  def map_layer_config_by_area_type(area_type)
    #only TAZ, Census_tract has multipe geometry versions
    geometry_base_year = @view.geometry_base_year if Area.is_versioned?(area_type)
    MapLayer.get_layer_config(area_type, geometry_base_year)
  end

  # ...
```

## app/services/

### app/services/bpm_summary_fact_symbology_service.rb

```ruby
class BpmSummaryFactSymbologyService < ViewSymbologyService
  def configure_symbology

    symbology_params = {
      is_default: true,
      view: @view,
      subject: 'TAZ Counts',
      symbology_type: Symbology::GEOMETRIC_BREAKS,
      number_formatter:  NumberFormatter.where(format_type: 'number', options:{
        format: '#,##0',
        locale: 'us'
        }.to_json).first_or_create
    }
```

### app/services/demographic_fact_symbology_service.rb

```ruby
class DemographicFactSymbologyService < ViewSymbologyService
  def configure_symbology
    # ...
    when 'TAZ Population'
      get_symbology_configs_for_population(symbology_params, Area::AREA_LEVELS[:taz])
```

## app/datatables/

### app/datatables/pivoted_datatable.rb

```ruby
class PivotedDatatable < AjaxDatatablesRails::Base
  # This depends on view
  def sortable_columns
    unless @sortable_columns
      # Check first column, which is usually special
      @sortable_columns = case options[:view].columns[0]
      when 'area'
        (options[:area_type] == "taz") ? ["CAST(areas.name AS INT)"] : ['Area.name']
```

## views/uploads/

### views/uploads/\_sed_upload_fields.html.slim

```slim
- geometry_versions = {"taz": BaseGeometryVersion.versions(:taz), "county": BaseGeometryVersion.versions(:county)}

  ...

  = form.input :data_level, label: 'Data Level', collection: ['TAZ', 'County'],include_blank: false, input_html: { class: 'upload_data_level form-control' }
.col-md-6
  = form.input :geometry_version, label: 'Area Boundary Base Year', collection: geometry_versions[:taz], include_blank: false, input_html: { class: 'upload_geometry_base_year form-control' }

  ...
```

### views/views/\_map_searchbox.html.slim

```slim
- show_searchbox = [DemographicFact, ComparativeFact, SpeedFact, LinkSpeedFact, RtpProject, TipProject].index(@view.data_model)
- if show_searchbox
  - search_prompt = 'Search '
  - search_help = ''
  - if !@view.data_levels.empty?
    - view_level = @view.data_levels[0].downcase
    - if view_level == 'taz'
      - search_prompt += 'TAZ'
      - search_help = 'Provide TAZ ID, e.g., 100'

  ...
```
