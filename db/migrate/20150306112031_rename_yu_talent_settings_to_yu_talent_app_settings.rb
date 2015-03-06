class RenameYuTalentSettingsToYuTalentAppSettings < ActiveRecord::Migration
  def change
    rename_table :yu_talent_settings, :yu_talent_app_settings
  end
end
