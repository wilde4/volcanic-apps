class RenameUserTypeToUserGroupName < ActiveRecord::Migration
  def change
    rename_column :mac_daxtra_users, :user_type, :user_group_name
  end
end
