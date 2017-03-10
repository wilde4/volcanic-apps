class AddUserIdToFilteredNotificationSending < ActiveRecord::Migration
  def change
    add_column :filtered_notification_sendings, :user_id, :integer
  end
end
