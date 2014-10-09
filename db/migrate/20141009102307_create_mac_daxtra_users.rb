class CreateMacDaxtraUsers < ActiveRecord::Migration
  def change
    create_table :mac_daxtra_users do |t|
      t.integer :user_id, index: true
      t.string :email
      t.string :user_type
      t.text :user_profile
      t.text :registration_answers

      t.timestamps
    end
  end
end
