Source.all.each do |source|
  # Users Not Logged In
  puts "Source ##{source.id} - Users Not Logged In"
  AccessControl.where({
    source_id: source.id,
    show: false
  }).first_or_create

  # Public Users
  puts "Source ##{source.id} - Public Users"
  AccessControl.where({
    role: "public",
    source_id: source.id,
    show: true
  }).first_or_create

  # Agency Users
  puts "Source ##{source.id} - Public Users"
  AccessControl.where({
    role: "agency",
    source_id: source.id,
    show: true,
    download: true,
    comment: true
  }).first_or_create

  source.views.each do |view|
    puts "View ##{view.id} - Users Not Logged In"
    AccessControl.where({
      view_id: view.id,
      show: false
    }).first_or_create

    # Public Users
    puts "View ##{view.id} - Public Users"
    AccessControl.where({
      role: "public",
      view_id: view.id,
      show: true
    }).first_or_create

    # Agency Users
    puts "View ##{view.id} - Public Users"
    AccessControl.where({
      role: "agency",
      view_id: view.id,
      show: true,
      download: true,
      comment: true
    }).first_or_create
  end
end
