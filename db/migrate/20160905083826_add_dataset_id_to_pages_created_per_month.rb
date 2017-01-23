class AddDatasetIdToPagesCreatedPerMonth < ActiveRecord::Migration
  def change
    add_column :pages_created_per_months, :dataset_id, :integer
  end
end
