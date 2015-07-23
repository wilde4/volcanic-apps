class CreateRegistrationBonuses < ActiveRecord::Migration
  def change
    create_table :registration_bonuses do |t|
      t.string :name
      t.integer :user_group_id
    end
  end
end
