class AddUserTypeToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :user_type, :string
  end
end
