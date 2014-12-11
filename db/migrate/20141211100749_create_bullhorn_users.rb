class CreateBullhornUsers < ActiveRecord::Migration
  def change
    create_table :bullhorn_users do |t|
      t.integer :user_id
      t.string :email
      t.text :user_data
      t.text :user_profile
      t.text :registration_answers
      t.integer :bullhorn_uid

      t.timestamps
    end
  end
end
