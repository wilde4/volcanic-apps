class RemoveUnusedAttributesFromArithonUsers < ActiveRecord::Migration
  def change
    remove_column :arithon_users, :project_id
    remove_column :arithon_users, :status_id
    remove_column :arithon_users, :type_id
  end
end
