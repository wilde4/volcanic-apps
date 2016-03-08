class RenameHashColumnsInBullhornAppSetting < ActiveRecord::Migration
  def change
    rename_column :bullhorn_app_settings, :bh_username_hash, :encrypted_bh_username
    rename_column :bullhorn_app_settings, :bh_password_hash, :encrypted_bh_password
    rename_column :bullhorn_app_settings, :bh_client_id_hash, :encrypted_bh_client_id
    rename_column :bullhorn_app_settings, :bh_client_secret_hash, :encrypted_bh_client_secret
  end
end
