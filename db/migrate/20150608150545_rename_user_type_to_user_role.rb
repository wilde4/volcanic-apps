class RenameUserTypeToUserRole < ActiveRecord::Migration
  def change
    rename_column :inventories, :user_type, :user_role
  end
end
