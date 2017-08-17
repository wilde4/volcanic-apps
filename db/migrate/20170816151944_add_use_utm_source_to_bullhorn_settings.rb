class AddUseUtmSourceToBullhornSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :use_utm_source, :boolean, default: false
  end
end
