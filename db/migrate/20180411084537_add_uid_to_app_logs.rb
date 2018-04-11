class AddUidToAppLogs < ActiveRecord::Migration
  def change
    add_column :app_logs, :uid, :string
  end
end
