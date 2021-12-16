require File.expand_path('../boot', __FILE__)

require 'rails/all'
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require 'open-uri'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# This is for when we are talking to a postgis database on heroku
class ActiveRecordOverrideRailtie < Rails::Railtie
  initializer "active_record.initialize_database.override" do |app|

    ActiveSupport.on_load(:active_record) do
      if url = ENV['DATABASE_URL']
        ActiveRecord::Base.connection_pool.disconnect!
        parsed_url = URI.parse(url)
        config =  {
          adapter:             'postgis',
          host:                parsed_url.host,
          encoding:            'unicode',
          database:            parsed_url.path.split("/")[-1],
          port:                parsed_url.port,
          username:            parsed_url.user,
          password:            parsed_url.password
        }
        ActiveRecord::Base.establish_connection(config)
      end
    end
  end
end

if ENV['GC_PROFILER_ENABLE']
  puts "+-----------------------+"
  puts "| ENABLING GC::Profiler |"
  puts "+-----------------------+"
  GC::Profiler.enable
end

module NymtcGateway
  class Application < Rails::Application

    # Allow disabling of IP spoofing check because of Rockland's awkward proxy situation
    config.action_dispatch.ip_spoofing_check = false if ENV['DISABLE_IP_SPOOFING_CHECK']

    # config.action_dispatch.default_headers = {
    #   'Access-Control-Allow-Origin' => '*',
    #   'Access-Control-Request-Method' => %w{GET POST OPTIONS}.join(",")
    # }

  
    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => %w{GET POST OPTIONS}.join(",")
    }

    # compress response
    config.middleware.use Rack::Deflater
    # don't generate RSpec tests for views and helpers
    config.generators do |g|
      
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      
      g.view_specs false
      g.helper_specs false
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    # config.autoload_paths += %W(#{config.root}/lib)
    config.eager_load_paths << Rails.root.join('lib')

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # config.active_record.whitelist_attributes = false

    # Enable the asset pipeline
    config.assets.enabled = true
    # Heroku requires this to be false
    config.assets.initialize_on_precompile=false

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.filepicker_rails.api_key = ENV['FILEPICKER_API_KEY']
    
    # Change the size limit to prevent OpenURI from creating StringIO objects instead of temp files
    OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
    OpenURI::Buffer.const_set 'StringMax', 0
  end
end
