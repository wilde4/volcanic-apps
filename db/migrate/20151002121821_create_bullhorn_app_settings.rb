class CreateBullhornAppSettings < ActiveRecord::Migration
  def change
    create_table :bullhorn_app_settings do |t|
      t.integer :dataset_id
      t.string :bh_username_hash
      t.string :bh_password_hash
      t.string :bh_client_id_hash
      t.string :bh_client_secret_hash
      t.boolean :import_jobs, default: 0

      t.timestamps
    end
  end
end
