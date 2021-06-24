class AddSourceReferenceToUploads < ActiveRecord::Migration
  def change
    add_reference :uploads, :source, index: true
  end
end
