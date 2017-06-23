class AddClientTokenToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :client_token, :string
  end
end
