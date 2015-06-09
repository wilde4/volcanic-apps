class AddCurrencyToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :currency, :string, default: "GBP"

    Inventory.where(dataset_id: 81).update_all(currency: "EUR")
  end
end
