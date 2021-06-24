new_action = Action.where(name: "view_metadata").first_or_create
puts "'View Metadata' action created"

Action.where(name: "metadata")
old_action = Action.where(name: "metadata")[0].update_attribute('name', 'edit_metadata') if !Action.where(name: "metadata").blank?
puts "'Metadata' action changed to 'Edit Metadata'"

View.all.each do |view|
  if view.actions.include?("edit_metadata") && !view.actions.include?(:view_metadata)
    view.add_action(:view_metadata)
    view.save
  end
end
puts "Views updated"
