class AddLinkedinAndSourceToBullhornAppSetting < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :linkedin_bullhorn_field, :string
    add_column :bullhorn_app_settings, :source_text, :string
  end
end
