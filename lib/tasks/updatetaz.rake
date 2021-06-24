namespace :tazupdate do
  
  desc "Enable 2012 TAZ boundary"
  task enable_2012_taz_boundary: :environment do
    require File.join(Rails.root, 'db', 'tasks/enable_2012_taz_boundary.rb')
    puts '2012 TAZ Boundary enabled'
  end

end
