web: bundle exec puma -C config/puma.rb
whacamole: bundle exec whacamole -c ./config/whacamole.rb
worker: bundle exec rake jobs:work
upload_worker: env QUEUE=uploads bundle exec rake jobs:work
