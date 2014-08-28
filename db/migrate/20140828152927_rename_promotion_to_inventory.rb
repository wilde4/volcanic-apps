class RenamePromotionToInventory < ActiveRecord::Migration
  def change
    rename_table :promotions, :inventory

    remove_column :inventory, :active
    remove_column :inventory, :default
    remove_column :inventory, :role_id

    add_column :inventory, :object_type, :string
  end
end
