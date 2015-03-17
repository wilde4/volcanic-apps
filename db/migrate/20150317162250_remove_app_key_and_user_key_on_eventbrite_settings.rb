class RemoveAppKeyAndUserKeyOnEventbriteSettings < ActiveRecord::Migration
  def change
    remove_column :eventbrite_settings, :app_key
    remove_column :eventbrite_settings, :user_key
  end
end
