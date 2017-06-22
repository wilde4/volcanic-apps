class AddCustomMappingColumnToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :custom_job_mapping, :boolean, default: 0
  end
end
