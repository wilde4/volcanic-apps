class AddJobStatusToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :job_status, :string
  end
end
