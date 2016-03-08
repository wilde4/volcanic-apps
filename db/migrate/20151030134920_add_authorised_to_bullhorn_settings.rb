class AddAuthorisedToBullhornSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :authorised, :boolean, default: 0
  end
end
