class RenameInventoryObject < ActiveRecord::Migration
  def change
    rename_column :inventories, :inventory_object_id, :object_type
    change_column :inventories, :object_type, :string
  end
end
