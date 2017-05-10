class AddOnlyFeaturedToTwitterAppSetting < ActiveRecord::Migration
  def change
    add_column :twitter_app_settings, :only_featured, :boolean, default: false
  end
end
