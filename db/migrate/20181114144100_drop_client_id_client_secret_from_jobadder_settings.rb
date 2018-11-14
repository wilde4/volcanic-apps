class DropClientIdClientSecretFromJobadderSettings < ActiveRecord::Migration
  def change
    remove_columns :jobadder_app_settings, :encrypted_ja_client_id, :encrypted_ja_client_secret
  end
end