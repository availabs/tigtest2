source 'https://rubygems.org'
ruby '2.7.4'
gem 'rails', '5.2.6'

# ===== Rails Server =====
# puma/puma: A Ruby/Rack web server built for parallelism
gem 'puma'
# mufid/rails-static-router: Enjoy static routes in your Rails config/routes.rb
gem 'rails-static-router'
# rails/activeresource: Connects business objects and REST web services.
gem 'activeresource'
# rails/activerecord-session_store: Active Record's Session Store extracted from Rails
gem 'activerecord-session_store'
# collectiveidea/delayed_job_active_record: ActiveRecord backend integration for DelayedJob 3.0+
gem 'delayed_job_active_record'
# heroku/rails_12factor: Makes running your Rails 4 (or 3) app easier. Based on the ideas behind 12factor.net
gem 'rails_12factor', group: [:integration, :production, :qa, :staging]
# thuehlinger/daemons: Ruby daemons gem official repository
gem "daemons"
# d4be4st/progress_job: Progress for Delayed job
gem 'progress_job'
# tenderlove/rails_autolink: The auto_link function from Rails
gem 'rails_autolink'
# ConsultingMD/activerecord5-redshift-adapter: Amazon Redshift adapter for ActiveRecord 5 (Rails 5).
gem "activerecord5-redshift-adapter", "~> 1.0"
# newrelic/newrelic-ruby-agent: New Relic RPM Ruby Agent
gem 'newrelic_rpm'

# ===== Configuration =====
# laserlemon/figaro: Simple Rails app configuration
gem 'figaro'

# ===== Authorization =====
# ryanb/cancan: Authorization Gem for Ruby on Rails.
gem 'cancan'
# heartcombo/devise: Flexible authentication solution for Rails with Warden.
gem 'devise'
# RolifyCommunity/rolify: Role management library with resource scoping
gem 'rolify'
# westonganger/protected_attributes_continued: community continued version of protected_attributes for Rails 5+
gem 'protected_attributes_continued'

# ===== Database =====
# ged/ruby-pg: A PostgreSQL client library for Ruby
gem 'pg'
# edjames/pivot_table: Transform an ActiveRecord-ish data set into pivot table
gem 'pivot_table', '= 0.4.0'
# Postgres database table partitioning support for Rails
# NOTE: Version specification: https://github.com/fiksu/partitioned/issues/70#issuecomment-233443202
gem 'partitioned', git: 'https://github.com/AirHelp/partitioned.git', branch: 'rails-5-2'

# ===== GIS =====
# rgeo/activerecord-postgis-adapter: ActiveRecord connection adapter for PostGIS, based on postgresql and rgeo
gem 'activerecord-postgis-adapter'
# rgeo/rgeo: Geospatial data library for Ruby.
gem 'rgeo'
# rgeo/rgeo-geojson: RGeo component for reading and writing GeoJSON
gem 'rgeo-geojson'
# rgeo/rgeo-shapefile: RGeo component for reading ESRI shapefiles
gem 'rgeo-shapefile'

# ===== Miscellaneous Data =====
# cph/mdb: A library for reading Microsoft Access databases
gem 'mdb'
# rubyzip/rubyzip: Official Rubyzip repository
gem 'rubyzip'
# filestack/filestack-rails: Makes integrating filepicker.io with rails 4 easy
gem 'filepicker-rails'
# roo-rb/roo: Roo provides an interface to spreadsheets of several sorts.
gem 'roo'
# brianmario/yajl-ruby: A streaming JSON parsing and encoding library for Ruby (C bindings to yajl)
gem 'yajl-ruby', require: 'yajl'

# ===== Front-End =====
# slim-template/slim-rails: Slim templates generator for Rails
gem 'slim-rails', '< 3.0'
gem 'sass-rails'
gem 'bootstrap-sass'
gem 'bootstrap3-datetimepicker-rails', '~> 4.0.0'
gem 'bootstrap-multiselect-rails'
gem 'coffee-rails'
gem 'uglifier', '>= 1.0.3'
gem 'font-awesome-rails'
# jgarber/redcloth: RedCloth is a Ruby library for converting Textile into HTML.
gem 'RedCloth'
# heartcombo/simple_form: Forms made easy for Rails!
gem 'simple_form'
# gazay/gon: https://github.com/gazay/gon/
gem 'gon'
# weppos/breadcrumbs_on_rails: A simple Ruby on Rails plugin for creating and managing a breadcrumb navigation.
gem 'breadcrumbs_on_rails'
# https://rubygems.org/gems/bootstrap-slider-rails: Make Bootstrap Slider available to Rails
# NOTE: GitHub repository no longer exists. Last update June 20, 2017.
gem 'bootstrap-slider-rails'
# winston/google_visualr: ...is a wrapper around the Google Chart Tools...
gem 'google_visualr'
# derekprior/momentjs-rails: The Moment.js JavaScript library ready to play with the Rails Asset Pipeline
gem 'momentjs-rails', '>= 2.8.1'
# manuelvanrijn/selectize-rails: A small gem for putting selectize.js into the Rails asset pipeline
gem 'selectize-rails'

# ========== Front-End::jQuery ==========
# gem 'jquery-datatables-rails', github: 'rweng/jquery-datatables-rails'
# ### Prior to dependencies upgrade:
# # gem 'jquery-datatables-rails', '= 3.3.0'
# # gem 'ajax-datatables-rails', '= 0.3.0'
# This one gave us some problems: https://rubygems.org/gems/ajax-datatables-rails/versions
gem 'jquery-datatables-rails'
gem 'ajax-datatables-rails'
gem 'jquery-rails'
gem "jquery-validation-rails"
gem 'jquery-ui-rails'

# ========== Front-End::Leaflet ==========
# axyjo/leaflet-rails: This gem provides the leaflet.js map display library for your Rails 5 application.
gem 'leaflet-rails', '= 0.7.4'
# NOTE: The following two leaflet gems currently (2021-10-24) have zero stars on GitHub.
# https://rubygems.org/gems/leaflet-draw-rails
# igor-drozdov/leaflet-draw-rails: Leaflet.draw plugin for your Rails application.
gem 'leaflet-draw-rails', '= 0.1.0'
# zentrification/leaflet-providers-rails: leaflet-providers plugin packaged for the rails 3 asset pipeline
gem 'leaflet-providers-rails', github: 'zentrification/leaflet-providers-rails'

group :development do
  # gem 'thin'
  gem 'better_errors'
  gem 'byebug'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'slim_lint'

  # NOTE: Lots of extensions: https://rubygems.org/search?query=rubocop
  gem 'rubocop'
  gem 'rubocop-rails', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false

  # brunofacca/active-record-query-trace
  gem 'active_record_query_trace'

  gem 'binding_of_caller'

  # === prettier ===

  # prettier/plugin-ruby: Prettier Ruby Plugin
  # NOTE: https://github.com/prettier/prettier/blob/main/website/data/editors.yml
  # gem prettier

  gem 'spring'

  # voormedia/rails-erd: Generate Entity-Relationship Diagrams for Rails applications
  # RUN: bundle exec erd
  gem 'rails-erd'

  # guard/guard: Guard is a command line tool to easily handle events on file system modifications.
  # gem 'guard'
  # gem 'guard-bundler'
  # gem 'guard-cucumber'
  # gem 'guard-rails'
  # gem 'guard-rspec'

  # zombocom/derailed_benchmarks: Go faster, off the Rails - Benchmarks for your whole Rails app
  # gem 'derailed_benchmarks'

end
#
group :development, :test do
  gem 'factory_girl_rails'
#   gem 'awesome_print'
  gem 'rspec-rails'
end

group :test do
#   gem 'capybara'
#   gem 'cucumber-rails', :require=>false
#   gem 'database_cleaner'
  gem 'email_spec'
#   gem 'launchy'
#   gem 'selenium-webdriver'
#   gem 'temping'
#   gem "ZenTest"
#   gem "autotest-rails"
#   gem 'simplecov'
end