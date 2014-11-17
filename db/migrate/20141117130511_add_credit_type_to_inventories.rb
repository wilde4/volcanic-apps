class AddCreditTypeToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :credit_type, :string
    rename_column :inventories, :object_type, :object_action
  end
end
