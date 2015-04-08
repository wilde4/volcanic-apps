class AddAccessTokenToYuTalentAppSettings < ActiveRecord::Migration
  def change
    add_column :yu_talent_app_settings, :access_token, :text
  end
end
