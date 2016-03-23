class DropBondAdaptUsers < ActiveRecord::Migration
  def change
    drop_table :bond_adapt_users
  end
end
