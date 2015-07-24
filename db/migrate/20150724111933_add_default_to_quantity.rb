class AddDefaultToQuantity < ActiveRecord::Migration
  def change
    change_column :registration_bonuses, :quantity, :integer, default: 0
  end
end
