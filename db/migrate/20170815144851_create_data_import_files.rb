class CreateDataImportFiles < ActiveRecord::Migration
  def change
    create_table :data_import_files do |t|
      t.string :filename
      t.references :profile, index: true
      t.integer  :user_group_id
      t.string   :uid
      t.string   :created_at_mapping
      t.integer  :max_size
      t.integer  :delay_interval
      t.string   :model
      t.integer  :user_id
      t.string   :post_mapping

      t.timestamps null: false
    end
  end
end
