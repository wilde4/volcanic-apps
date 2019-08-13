class CreateV10SyncSettings < ActiveRecord::Migration
  def change
    create_table :v10_sync_settings do |t|
      t.integer :dataset_id
      t.string :endpoint
      t.string :api_key
    end
  end
end
