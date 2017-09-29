class AddExtraOauthFieldsToBullhornSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :access_token, :string
    add_column :bullhorn_app_settings, :access_token_expires_at, :datetime
    add_column :bullhorn_app_settings, :rest_token, :string
    add_column :bullhorn_app_settings, :rest_url, :string
  end
end
