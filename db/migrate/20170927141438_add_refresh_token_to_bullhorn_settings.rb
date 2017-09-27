class AddRefreshTokenToBullhornSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :refresh_token, :string
  end
end
