class AddPollFrequencyToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :poll_frequency, :integer, default: 1
    add_column :bullhorn_app_settings, :poll_count, :integer, default: 1
  end
end
