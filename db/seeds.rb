# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) can be set in the file config/application.yml.
# See http://railsapps.github.io/rails-environment-variables.html
require 'csv'

puts 'ROLES'
YAML.load(ENV['ROLES']).each do |role|
  Role.find_or_create_by(name: role)
  puts 'role: ' << role
end
puts 'DEFAULT USERS'
user = User.find_or_create_by(display_name: ENV['ADMIN_NAME'].dup,
                              email: ENV['ADMIN_EMAIL'].dup)
user.update_attributes(password: ENV['ADMIN_PASSWORD'].dup,
                       password_confirmation: ENV['ADMIN_PASSWORD'].dup)
puts 'user: ' << user.display_name
user.add_role :admin
user.password = user.password_confirmation = ENV['ADMIN_PASSWORD'].dup
user.save!
puts 'user: ' << user.display_name

user = User.find_or_create_by(display_name: "Test User", 
                              email: "user@example.com")
user.update_attributes(password: "password",
                       password_confirmation: "password")
puts 'user: ' << user.display_name

puts 'ACTIONS'
YAML.load(ENV['ACTIONS']).each do |action|
  Action.find_or_create_by(name: action)
end
puts Action.pluck(:name)

puts 'DEFAULT CATALOG'
# seed some serious data here

sedSource = Source.find_or_create_by(name: 'SED Forecast Data')

sedSource.update_attributes(:current_version => 3,
                            :data_starts_at => DateTime.new(1970),
                            :data_ends_at => DateTime.new(2040),
                            :description =>
"Socioeconomic forecast data for population and employment with forecasts
 ranging from 2020 to 2040.",
                            :origin_url => "https://wiki.camsys.com/display/TIG/NYMTC+TIG+Public",
                            :user => user,
                            :rows_updated_at => DateTime.now,
                            :rows_updated_by => user,
                            :topic_area => "Demographics")

popStat = Statistic.find_or_create_by(name: "Population")
popStat.update_attributes(scale: 3)

if ENV["load_sed"]
  popView2020 = View.find_or_create_by(name: "2020 County Population Forecast")
  popView2020.update_attribute(:source, sedSource)
  popView2020.update_attributes(
                                data_starts_at: "1970-01-01",
                                data_ends_at: "2020-01-01",
                                description:
                                "Population forecast through 2020. Includes historical data from 1970 for comparison.",
                                current_version: 2,
                                origin_url: sedSource.origin_url,
                                user: user,
                                rows_updated_at: DateTime.now,
                                rows_updated_by: user,
                                topic_area: "Demographics",
                                download_count: 3,
                                last_displayed_at: DateTime.now,
                                view_count: 23,
                                statistic: popStat,
                                data_model: DemographicFact,
                                columns: ['area', '1970', '1980', '1990', '1995', '2000',
                                          '2005', '2010', '2015', '2020'],
                                column_types: ['', 'numeric', 'numeric', 'numeric', 'numeric',
                                               'numeric', 'numeric', 'numeric', 'numeric', 'numeric'],
                                data_levels: [Area::AREA_LEVELS[:county]],
                                value_name: :density
                                )
  popView2020.add_action :table
  popView2020.add_action :map
  popView2020.add_action :chart
  popView2020.add_action :metadata

  columns = 2000.step(2040, 5).map { |year| year.to_s }
  columns.unshift 'area'
  column_types = columns.count.times.map {|| 'numeric' }
  column_types.unshift ''

  popCountyView2040 = View.find_or_create_by(name: "2040 County Population Forecast")
  popCountyView2040.update_attribute(:source, sedSource)
  popCountyView2040.update_attributes(
                                      data_starts_at: "2020-01-01",
                                      data_ends_at: "2040-01-01",
                                      description: "Population for 2040 (in 000s).",
                                      statistic: popStat,
                                      data_model: DemographicFact,
                                      columns: columns,
                                      column_types: column_types,
                                      data_levels: [Area::AREA_LEVELS[:county]], 
                                      value_name: :value
                                      )

  popCountyView2040.add_action :map
  popCountyView2040.add_action :table
  popCountyView2040.add_action :chart
  popCountyView2040.add_action :metadata

  Area.delete_all
  DemographicFact.delete_all
  DemographicFact.loadCSV('db/AllPopulation2020.csv', popView2020, popStat, Area::AREA_LEVELS[:subregion], Area::AREA_LEVELS[:county])
  DemographicFact.loadCSV('db/AllPopulation2040.csv', popCountyView2040, popStat, Area::AREA_LEVELS[:subregion], Area::AREA_LEVELS[:county])

  if ENV["load_taz"]
    tazPopStat = Statistic.find_or_create_by(name: "TAZ Population")
    tazPopStat.update_attributes(scale: 1)
    popTazView2040 = View.find_or_create_by(name: "2040 TAZ Population Forecast")
    popTazView2040.update_attribute(:source, sedSource)
    popTazView2040.update_attributes(
                                  data_starts_at: "2020-01-01",
                                  data_ends_at: "2040-01-01",
                                  description: "Population for 2040",
                                  statistic: tazPopStat,
                                  data_model: DemographicFact,
                                  columns: columns,
                                  column_types: column_types,
                                  data_levels: [Area::AREA_LEVELS[:taz]], 
                                  value_name: :value
                                  )

    popTazView2040.add_action :map
    popTazView2040.add_action :table
    popTazView2040.add_action :metadata
    DemographicFact.loadCSV('db/TAZPop2010to2040.csv', popTazView2040, tazPopStat, Area::AREA_LEVELS[:county], Area::AREA_LEVELS[:taz])
  end
  
  puts DemographicFact.all.count.to_s + " Demographic Facts"
end

# Add sizes to areas
Area.loadCSV('db/area_size.csv')
Area.loadCSV('db/taz_area_size.csv')

# Add NYBPM and TCC areas
mhs = Area.find_or_create_by(name: "Mid Hudson South", type: :subregion)
['Putnam', 'Rockland', 'Westchester'].each do |name|
  area = Area.find_by(name: name)
  area.enclosing_areas << mhs unless area.enclosing_areas.include? mhs
  area.save!
end

nybpm = Area.find_or_create_by(name: 'NYBPM Counties', type: :region)
counties = Area.where(type: :county).pluck(:name) - ['Litchfield', 'Sullivan', 'Ulster']
counties.each do |county|
  area = Area.find_by(name: county)
  area.enclosing_areas << nybpm unless area.enclosing_areas.include? nybpm
  area.save!
end
  
nymtc = Area.find_or_create_by(name: 'NYMTC Planning Area', type: :region)
if nymtc.enclosed_areas.empty?
  nymtc.enclosed_areas << mhs.enclosed_areas
  nymtc.enclosed_areas << Area.find_by(name: "New York City").enclosed_areas
  nymtc.enclosed_areas << Area.find_by(name: "Long Island").enclosed_areas
end

rtpSource = Source.find_or_create_by(name: 'RTP Project Data')
if rtpSource.views.count < 1
  rtpSource.add_view("Current RTP Project List")
  rtpSource.add_view("Potential Future RTP Projects")
end
rtpSource.update_attributes(:origin_url => "http://nymtc.org/")

rtpView = View.find_or_create_by(name: 'Current RTP Project List')
rtpView.update_attributes(description: "Current RTP Projects",
                          data_model: RtpProject,
                          columns: ['rtp_id', 'description', 'year', 'estimated_cost',
                                    'plan_portion',
                                    'sponsor', 'county', 'ptype'],
                          column_types: ['', '', '', 'millions', '', '', '', ''],
                          data_levels: ['Project']
                          )

if ENV['load_projects']
  RtpProject.destroy_all
  RtpProject.loadCSV('db/point_proj.csv', rtpView)
  RtpProject.loadCSV('db/polygon_proj.csv', rtpView)
  RtpProject.loadCSV('db/line_proj.csv', rtpView)
  puts RtpProject.all.count.to_s + " RTP Projects"
end

rtpView.add_action :table
rtpView.add_action :map
rtpView.add_action :view_metadata
rtpView.add_action :edit_metadata

# Maintain this in case we want to restore BPM Model Results as a demo but otherwise delete.
bpmSourceName = 'BPM Model Results'
bpmViewNames = ['2015 Baseline 2015-02-02',
                '2020 No Build No Build 2015-06-06',
                '2020 No Build No Build 2015-06-20']

if ENV["include_bpm"]
  bpmSource = Source.find_or_create_by(name: bpmSourceName)
  bpmViewNames.each {|name| bpmSource.add_view(name)} if bpmSource.views.count < 1

  bpmView = View.find_or_create_by(name: '2020 No Build No Build 2015-06-20')
  bpmView.update_attributes(data_model: BpmSummaryFact,
                            columns: ['area', 'orig_dest', 'purpose', 'mode', 'count']
                            )

  if ENV["load_bpm"]
    BpmSummaryFact.delete_all
    BpmSummaryFact.loadCSV('db/taz_summaries.csv', bpmView, 2020)
    puts BpmSummaryFact.count.to_s + " BPM Facts"
  end
  bpmView.add_action :table
  bpmView.add_action :map
else
  bpmViewNames.each {|name| View.delete_all(name: name)}
  Source.delete_all(name: bpmSourceName)
end

# Turn off TRANSCOM for now but possibly restore later
xcomSourceName = 'TRANSCOM Data'
xcomViewNames = ["Derived Performance Measures", "Speeds and Volumes", "Events"]
if ENV["include_xcom"]
  source2 = Source.find_or_create_by(name: xcomSourceName)
  xcomViewNames.each {|name| source2.add_view(name) } if source2.views.count < 1
else
  xcomViewNames.each {|name| View.delete_all(name: name) }
  Source.delete_all(name: xcomSourceName)
end

if ENV["load_bpm_2005_taz_forecast"]
  require File.join(Rails.root, 'db', 'bpm_2005_taz_forecast_seeds.rb')
end

if ENV["load_acs_data"]
  require File.join(Rails.root, 'db', 'acs_data_seeds.rb')
end

if ENV["load_area_geometry"]
  require File.join(Rails.root, 'db', 'area_geometry_seeds.rb')
end

if ENV["load_base_overlay"]
  require File.join(Rails.root, 'db', 'base_overlay_seeds.rb')
end

if ENV["load_tmc"]
  require File.join(Rails.root, 'db', 'load_tmc_seeds.rb')
end

if ENV["load_rds"]
  require File.join(Rails.root, 'db', 'load_rds_seeds.rb')
end

puts 'Update TMC Index'
# Significantly improves the speed of sorting SpeedFacts by Tmc
Tmc.transaction do
  start_index = (Tmc.maximum(:index) || 0) + 1;
  Tmc.where(index: nil).order(:name).each_with_index {|tmc, i| tmc.update_attributes(index: start_index + i) }
end

