class CreateInventoryObject < ActiveRecord::Migration
  def change
    create_table :inventory_objects do |t|
      t.string :name
      t.string :attrib
    end
  end
end
