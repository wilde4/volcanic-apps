class CreateBondAdaptUsers < ActiveRecord::Migration
  def change
    create_table :bond_adapt_users do |t|
      t.integer :user_id
      t.string :email
      t.text :user_data
      t.text :user_profile
      t.text :registration_answers
      t.text :linkedin_profile
      t.integer :bond_adapt_uid

      t.timestamps
    end
  end
end
