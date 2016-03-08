class AddCvSearchEnabledToCvSearchSettings < ActiveRecord::Migration
  def change
    add_column :cv_search_settings, :cv_search_enabled, :boolean, default: true
  end
end
