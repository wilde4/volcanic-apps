class CreateFilteredNotificationSending < ActiveRecord::Migration
  def change
    create_table :filtered_notification_sendings do |t|
      t.integer :job_id
      t.text :client_ids
      t.timestamps
    end
  end
end
