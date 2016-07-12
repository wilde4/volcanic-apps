class AddUsesPublicFilterToBullhornSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :uses_public_filter, :boolean, default: false
  end
end
