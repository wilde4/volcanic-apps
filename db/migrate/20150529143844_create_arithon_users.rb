class CreateArithonUsers < ActiveRecord::Migration
  def change
    create_table :arithon_users do |t|
      t.integer :user_id
      t.string :email
      t.text :user_data
      t.text :user_profile
      t.text :registration_answers
      t.integer :arithon_candidateid

      t.timestamps
    end
  end
end
