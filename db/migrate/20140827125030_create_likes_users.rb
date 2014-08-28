class CreateLikesUsers < ActiveRecord::Migration
  def change
    create_table :likes_users do |t|
      t.integer :user_id, index:true
      t.string :email
      t.string :first_name
      t.string :last_name
      t.text :extra
      t.text :registration_answers

      t.timestamps
    end
  end
end
