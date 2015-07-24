class ChangeUserGroupColumn < ActiveRecord::Migration
  def change
    rename_column :registration_bonuses, :user_group_id, :user_group
    change_column :registration_bonuses, :user_group, :string
  end
end
