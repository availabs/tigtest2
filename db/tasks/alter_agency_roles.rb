puts "Renaming 'Agency' role"
role = Role.where(name: "agency").first_or_create
role.name = "agency_user"
role.save

puts "Adding 'Agency Admin' role"
Role.where(name: "agency_admin").first_or_create
