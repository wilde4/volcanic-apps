class AddExpireClosedJobsColumnToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :expire_closed_jobs, :boolean, default: false
  end
end
