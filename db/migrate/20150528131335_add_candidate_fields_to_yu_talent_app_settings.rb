class AddCandidateFieldsToYuTalentAppSettings < ActiveRecord::Migration
  def change
    add_column :yu_talent_app_settings, :background_info, :string
    add_column :yu_talent_app_settings, :company_name, :string
    add_column :yu_talent_app_settings, :location, :string
    add_column :yu_talent_app_settings, :history, :string
    add_column :yu_talent_app_settings, :education, :string
    add_column :yu_talent_app_settings, :facebook, :string
    add_column :yu_talent_app_settings, :linkedin, :string
    add_column :yu_talent_app_settings, :phone, :string
    add_column :yu_talent_app_settings, :phone_mobile, :string
    add_column :yu_talent_app_settings, :position, :string
  end
end
