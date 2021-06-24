Whacamole.configure(ENV['APP_NAME'] || 'gateway-prod') do |config|
  # Can be run locally for testing/monitor or on Heroku for continuous support
  # heroku ps:scale whacamole=1 --app APP_NAME
  config.api_token = ENV['HEROKU_API_TOKEN'] || Bundler.with_clean_env{`heroku auth:token`}
  # 
  # in megabytes. default is 1000 (good for 2X dynos)
  config.restart_threshold = ENV['RESTART_THRESHOLD'] ? ENV['RESTART_THRESHOLD'].to_i : 1000 
end
