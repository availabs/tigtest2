# TAZ-Related DB Migrations

## db/tasks/enable_2012_taz_boundary.rb

This file loads the TAZ geometries.

### the script creates the MapLayer

```ruby
version = '2012'
#seed 201 TAZ MapBox URL to MapLayers
if MapLayer.where(category: :taz, version: version).empty?
  config = {
    layer_type: 'PBF_TILE',
    version: version,
    category: "taz",
    url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.0c163d91/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
    name: 'NYBPM_TAZ_2012',
    reference_column: 'TAZ_ID',
    title: 'NYBPM 2012 TAZs',
    geometry_type: 'POLYGON',
    attribution: 'TAZ map data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>',
    style: {
      size: 1,
      outline: {
        color: "transparent",
        size: 0.1
      }
    }.to_s
  }

  MapLayer.create(config)
end
```

### the script deletes any existing DemographicFacts for the TAZ year

```ruby
# remove existing 2012 TAZ areas and associated view data
puts "deleting"
DemographicFact.joins(:area).where(areas: {type: :taz, year: 2012}).delete_all
Area.where(type: :taz, year: 2012).delete_all
puts "done deleting"
```

### the script loads the BaseGeometries as GeoJSON

```ruby
# main function to load geometries from a geojson file to postgis table
def load_geom_from_geojson(geom_config)
  if !BaseGeometry
    return
  end

  geom_config = geom_config || {};
  file_path = geom_config[:file_name]
  match_column = geom_config[:match_column]
  match_county_column = geom_config[:match_county_column]
  is_titleize_name = geom_config[:titleize_name] rescue nil

  puts "loading file"

  input_file = File.read(file_path)
  factory = RGeo::Cartesian.factory(srid: 4326)
  features = RGeo::GeoJSON.decode(input_file, :json_parser => :json, :geo_factory => factory)

  puts "processing features"
  features.each do |feature|
    name = feature[match_column].to_s
    next if name.blank?
    area = Area.where(name: name, type: :taz, year: 2012).first_or_create

    # enclosing relation
    county_name = feature[match_county_column].to_s
    county = Area.where(name: county_name, type: :county).first
    area.enclosing_areas << county if county

    if !area.base_geometry
      area.base_geometry = BaseGeometry.new
    end
    area.base_geometry.update_attributes(:geom => feature.geometry)
    area.base_geometry.save!
  end
  puts "updating BaseGeometryVersion"
  bgv_convig = {
    category: "taz",
    version: 2012
  }

  BaseGeometryVersion.create(bgv_convig)
end
```

## db/bpm_2005_taz_forecast_seeds.rb

The comment atop the file:

```ruby
# This seeding script is only executed when ENV['load_bpm_2005_taz_forecast'] = true
#   Please make sure Areas table already has the area associated with the data source file to load
#   e.g., NYBPM_2005_TAZ_Forecast.csv is TAZ level based, then you need to have TAZ areas in Areas table
# Choose Statatistics to load
#   1. Check available stats by looking at AVAILABLE_STATISTICS hash keys
#   2. list statistic key in ENV cmd via STATS_TO_LOAD=[]
#     e.g., STATS_TO_LOAD='school_enrollment,total_employment'
# A full sample command
#   rake db:seed load_bpm_2005_taz_forecast=true STATS_TO_LOAD='school_enrollment,total_employment'
```

Note: This file has a configuration object to load a CSV file:

```ruby
# prepare configs for one source / file
bpm_forecast_config = {
  :file_name => File.join(Rails.root, 'db', 'NYBPM_2005_TAZ_Forecast.csv'),
  :area_level => Area::AREA_LEVELS[:taz], #optional
  :area_value_column => 'TAZ',
  :source => {
    :name => 'SED Forecast Data',
    :current_version => 1,
    :data_starts_at => DateTime.new(2010),
    :data_ends_at => DateTime.new(2040),
    :description => "NYMTC Socio-economic forecast data ranging from 2010 to 2040.",
    :origin_url => "https://wiki.camsys.com/display/TIG/NYMTC+TIG+Public",
    :rows_updated_at => DateTime.now,
    :topic_area => "Demographics"
  },
  :statistics => []
}
```

Notice that the name in the scripts `bpm_forecast_config` is _"SED Forecast Data"_.
That name does not appear in the TIG production database:

```psql
nymtc_test=# select name, description, created_at, updated_at from sources where topic_area = 'Demographics';
-[ RECORD 1 ]------------------------------------------------------------------------------
name        | 2040 SED County Level Forecast Data
description | NYMTC Socio-economic forecast data at county level ranging from 2000 to 2040.
created_at  | 2015-07-31 21:25:37.864038
updated_at  | 2016-06-07 12:44:17.591114
-[ RECORD 2 ]------------------------------------------------------------------------------
name        | 2040 SED TAZ Level Forecast Data
description | NYMTC Socio-economic forecast data ranging from 2010 to 2040.
created_at  | 2014-11-20 18:59:07.499279
updated_at  | 2019-07-22 20:00:36.812386
```

However, this script was added to the repository 2014-11-20.

```sh
git --no-pager log --diff-filter=A -- db/bpm_2005_taz_forecast_seeds.rb
commit 63ec73976f854ea158a84ad2ec05b60c561f9815
Author: Xudong Liu <xudongliu@camsys.com>
Date:   Thu Nov 20 13:18:41 2014 -0500

    add seeding for nybpm 2005 taz forecast; added two views: school enrollment and total population.
```

That's the created_at date for the source named '2040 SED TAZ Level Forecast Data'.

Additionally, the database entry for the source named '2040 SED County Level
Forecast Data' was created on the around the same date that
db/tasks/load_2040_sed_county_forecast.rb was added.

```sh
$ git --no-pager log --diff-filter=A -- db/tasks/load_2040_sed_county_forecast.rb
commit 9adffca4f502dcf3d96642695c8d64dd8096365a
Author: Xudong Liu <xudong.camsys@gmail.com>
Date:   Fri Jun 19 10:39:02 2015 -0400

    [finishes#93723460]added rake tast to seed 2040 SED county level forecast data
```

**Conclusion:** The _'2040 SED TAZ Level Forecast Data'_ was added using
the _db/bpm_2005_taz_forecast_seeds.rb_ script, then the name was edited
using the UI after County Level Forecast Data was added.

### The db/bpm_2005_taz_forecast_seeds.rb script and the TIG Data Model

The following shows the entity relationships in the database.

```erd
source -1---*- view -1---*- demographic_fact -*---1- statistic
```

### the script determines which stats to load from the CSV

```ruby
# Choose Statatistics to load
#   1. Check available stats by looking at AVAILABLE_STATISTICS hash keys
#   2. list statistic key in ENV cmd via STATS_TO_LOAD=[]
#     e.g., STATS_TO_LOAD='school_enrollment,total_employment'
# A full sample command
#   rake db:seed load_bpm_2005_taz_forecast=true STATS_TO_LOAD='school_enrollment,total_employment'

# available statistics to load
VIEW_SETS = {
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

VIEW_TEMPLATE = {
      :actions => [:table, :map, :metadata],
      :options => {
        data_starts_at: DateTime.new(2010),
        data_ends_at: DateTime.new(2040),
        rows_updated_at: DateTime.now,
        data_levels: [Area::AREA_LEVELS[:taz]],
        topic_area: "Demographics",
        data_model: DemographicFact,
        columns: ['area'].concat(2010.step(2040, 5).map { |year| year.to_s }),
        column_labels: ['TAZ'].concat(2010.step(2040, 5).map { |year| year.to_s }),
        column_types: [''].concat(2010.step(2040, 5).map { |year| 'numeric' }),
        value_name: :value
  }
}

AVAILABLE_STATISTICS = {}

VIEW_SETS.each do |k, v|
  name = k.to_s.titleize
  mappings = []
  (10..40).step(5) do |year|
    full_year = 2000 + year
    mappings << {
      :field => v[:prefix] + year.to_s,
      :year => full_year
    }
  end

  set = {
    :statistic => {
      :name => name
    },
    :view => Hash[VIEW_TEMPLATE],
    :precision => v[:precision]
  }
  set[:view][:name] = "2010-2040 #{name}"
  set[:view][:description] = v[:desc]
  set[:view][:field_mappings] = mappings

  AVAILABLE_STATISTICS[k] = set
end


# find stats to load
# check AVAILABLE_STATISTICS{} keys for available stat indexes to be used in seed cmd
if ENV["STATS_TO_LOAD"]
  STATS_TO_LOAD = ENV["STATS_TO_LOAD"].to_s.split(',') || []
end
if STATS_TO_LOAD.count == 1 && STATS_TO_LOAD[0].strip.downcase == "all"
  load_set = VIEW_SETS.keys
else
  load_set = STATS_TO_LOAD
end
```

A sample of the available columns in NYBPM_2005_TAZ_Forecast.csv:

```sh
$ head -1 NYBPM_2005_TAZ_Forecast.csv | tr ',' '\n' | sort | head -n25
County FIPS
Earn10
Earn15
Earn20
Earn25
Earn30
Earn35
Earn40
EmpLF10
EmpLF15
EmpLF20
EmpLF25
EmpLF30
EmpLF35
EmpLF40
EmpOff10
EmpOff15
EmpOff20
EmpOff25
EmpOff30
EmpOff35
EmpOff40
EmpRet10
EmpRet15
EmpRet20
```

### the script first creates a new Source:

```ruby
source = Source.find_or_create_by(name: source_config[:name])
source_config.each do |attr, value|
  source.update_attribute(attr, value)
end
```

Then the script extracts all Area IDs in the CSV
where there is a corresponding Area in the
_areas_ database table. This means that
**the areas shapefile MUST be loaded before the CSV**,
as stated in the "usage" comment atop the script.

```ruby
area_lookup = []
area_row_data.each do |area_value|
  area = Area.where(name: area_value.to_s).first

  if area
    area_lookup << area.id
  else
    area_lookup << nil
  end
end
```

#### the script upserts statistics, views, and demographic_facts

For each Statistic, the script UPSERTs a View.
For each field mapping in the View, the script UPSERTs a DemographicFact.

```ruby
stats.each do |obj|
  stat_config = obj[:statistic]
  if stat_config
    stat = Statistic.find_or_create_by(name: stat_config[:name])
    stat_config.each do |attr, value|
      stat.update_attribute(attr, value)
    end
    puts 'statistic: ' + stat.name
  end

  view_config = obj[:view]
  if view_config
    view = View.where(name: view_config[:name], source: source, statistic: stat).first
    if !view
      view = View.create(name: view_config[:name])
      view.update_attribute(:source, source)
      view.update_attribute(:statistic, stat)
    end
    view.update_attributes(description: view_config[:desc])

    view_config_options = view_config[:options] || {}
    view_config_options.each do |attr, value|
      view.update_attribute(attr, value)
    end
    precision = obj[:precision] || 0
    if precision == 2
      view.update_attribute(:column_types, [''].concat(2010.step(2040, 5).map { |year| 'float' }))
    end

    actions = view_config[:actions] || []
    actions.each do |action|
      view.add_action action.to_sym
    end
    puts 'view: ' + view.name

    fields = view_config[:field_mappings] || []

    fields.each do |field_config|
      field_name = field_config[:field]
      year = field_config[:year]

      field_data = csv_data[field_name.downcase.to_sym]
      field_data.each_with_index do |value, index|
        area_id = area_lookup[index]
        if !area_id # no match area for this row
          next
        end

        rec = DemographicFact.where(
          view: view,
          year: year,
          statistic: stat,
          area_id: area_id
        ).first_or_create

        rec.update_attribute(:value, value.to_f.round(precision))
      end
    end
    puts "#{DemographicFact.where(view: view).count} facts"
  end
end
```

---

## Apparently Deprecated

### The tl_2011\_\*\_taz10 tables

```psql
nymtc_development=# \dt *taz*
              List of relations
 Schema |       Name       | Type  |  Owner
--------+------------------+-------+----------
 public | tl_2011_09_taz10 | table | postgres
 public | tl_2011_34_taz10 | table | postgres
 public | tl_2011_36_taz10 | table | postgres
(3 rows)
```

These tables are in the _db/schema.rb_ file:

```sh
$ ag taz db/schema.rb
697:  create_table "tl_2011_09_taz10", force: true do |t|
703:    t.string  "tazce10",    limit: 8
713:  add_index "tl_2011_09_taz10", ["geom"], :name => "sidx_tl_2011_09_taz10_geom", :spatial => true
715:  create_table "tl_2011_34_taz10", force: true do |t|
721:    t.string  "tazce10",    limit: 8
731:  add_index "tl_2011_34_taz10", ["geom"], :name => "sidx_tl_2011_34_taz10_geom", :spatial => true
733:  create_table "tl_2011_36_taz10", force: true do |t|
739:    t.string  "tazce10",    limit: 8
749:  add_index "tl_2011_36_taz10", ["geom"], :name => "sidx_tl_2011_36_taz10_geom", :spatial => true
```

However, there is not other reference to these tables in the db/ or app/ directories.
It is unclear how they were created and loaded, or their potential use.
