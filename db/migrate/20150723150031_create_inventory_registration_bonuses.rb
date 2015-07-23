class CreateInventoryRegistrationBonuses < ActiveRecord::Migration
  def change
    create_table :inventory_registration_bonuses do |t|
      t.integer :inventory_id
      t.integer :registration_bonus_id
      t.integer :quantity
    end
  end
end
