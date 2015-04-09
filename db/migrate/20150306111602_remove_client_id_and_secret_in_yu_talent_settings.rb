class RemoveClientIdAndSecretInYuTalentSettings < ActiveRecord::Migration
  def change
    remove_column :yu_talent_settings, :client_id
    remove_column :yu_talent_settings, :client_secret
  end
end
