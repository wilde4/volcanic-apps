class RenamePromotionToInventory < ActiveRecord::Migration
  def change
    rename_table :promotions, :inventories

    remove_column :inventories, :active
    remove_column :inventories, :default
    remove_column :inventories, :role_id

    add_column :inventories, :object_type, :string
  end
end
