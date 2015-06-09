class RenameUserRoleToUserGroup < ActiveRecord::Migration
  def change
    rename_column :inventories, :user_role, :user_group
  end
end
