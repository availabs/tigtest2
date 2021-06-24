watch_action = Action.find_by(name: "watch")
View.all.each { |view| view.roles << watch_action if !view.roles.include?(watch_action) }
