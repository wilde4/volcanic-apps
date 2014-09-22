class CreateTextLocalLogs < ActiveRecord::Migration
  def change
    create_table :text_local_logs do |t|
      t.integer :user_id
      t.string :mobile_number
      t.text :message
      t.string :sender

      t.timestamps
    end
  end
end
