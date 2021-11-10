namespace :tazupdate2020 do

  desc "Enable 2020 TAZ boundary"
  task enable_2020_taz_boundary: :environment do
    require File.join(Rails.root, 'db', 'tasks/enable_2020_taz_boundary.rb')
    puts '2020 TAZ Boundary enabled'
  end

end
