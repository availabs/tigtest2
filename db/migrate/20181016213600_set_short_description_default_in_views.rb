# Where there is no short_description,
#   set it to the first sentence of the description.
# See: https://stackoverflow.com/a/9094014

class SetShortDescriptionDefaultInViews < ActiveRecord::Migration
  def change
    View
      .where("short_description IS NULL") 
      .update_all("short_description = LEFT(description, STRPOS(description, '.'))")
  end
end
