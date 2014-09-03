class RenameDatasetIdOnKey < ActiveRecord::Migration
  def change
    rename_column :keys, :dataset_id, :app_dataset_id
  end
end
