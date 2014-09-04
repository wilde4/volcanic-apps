class DropInventoryObjects < ActiveRecord::Migration
  def change
    drop_table :inventory_objects
  end
end
