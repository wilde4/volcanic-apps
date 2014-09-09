class ChangeObjectTypeOnInventory < ActiveRecord::Migration
  def change
    #rename_column :inventories, :object_type, :inventory_object_id
    change_column :inventories, :inventory_object_id, :integer
  end
end
