class RenameRefreshTokenToAccessToken < ActiveRecord::Migration
  def change
    rename_column :yu_talent_app_settings, :refresh_token, :authorization_code
  end
end
