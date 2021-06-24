class AddViewToCountFact < ActiveRecord::Migration
  def change
    add_reference :count_facts, :view, index: true
  end
end
