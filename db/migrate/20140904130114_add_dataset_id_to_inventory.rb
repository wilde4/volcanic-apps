class AddDatasetIdToInventory < ActiveRecord::Migration
  def change
    add_column :inventories, :dataset_id, :integer
  end
end
