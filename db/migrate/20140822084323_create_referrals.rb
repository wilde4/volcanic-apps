class CreateReferrals < ActiveRecord::Migration
  def change
    create_table :referrals do |t|
      t.belongs_to :user
      t.string :token

      t.boolean :confirmed
      t.datetime :confirmed_at

      t.boolean :revoked
      t.datetime :revoked_at

      t.timestamps
    end
  end
end
