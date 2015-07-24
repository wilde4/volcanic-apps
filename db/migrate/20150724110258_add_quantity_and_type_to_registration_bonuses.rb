class AddQuantityAndTypeToRegistrationBonuses < ActiveRecord::Migration
  def change
    add_column :registration_bonuses, :quantity, :integer
    add_column :registration_bonuses, :credit_type, :string
  end
end
