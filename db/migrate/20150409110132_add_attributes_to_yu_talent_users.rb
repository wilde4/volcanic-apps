class AddAttributesToYuTalentUsers < ActiveRecord::Migration
  def change
    add_column :yu_talent_users, :project_id, :integer
    add_column :yu_talent_users, :status_id,  :string
    add_column :yu_talent_users, :type_id,    :integer
  end
end
