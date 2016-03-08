class AddAlwaysCreateToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :always_create, :boolean, default: false
  end
end
