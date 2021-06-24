class AddUserReferenceToAreas < ActiveRecord::Migration
  def change
    add_reference :areas, :user, index: true
  end
end
