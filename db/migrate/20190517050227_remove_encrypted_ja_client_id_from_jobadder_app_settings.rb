class RemoveEncryptedJaClientIdFromJobadderAppSettings < ActiveRecord::Migration
  def change
    remove_column :jobadder_app_settings, :encrypted_ja_client_id, :varchar
    remove_column :jobadder_app_settings, :encrypted_ja_client_secret, :varchar

  end
end
