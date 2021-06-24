class AddDelayedJobToUpload < ActiveRecord::Migration
  def change
    add_reference :uploads, :delayed_job, index: true
  end
end
