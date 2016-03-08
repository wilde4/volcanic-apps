class AddClientTokenToCvSearchAccessDurations < ActiveRecord::Migration
  def change
    add_column :cv_search_access_durations, :client_token, :string
    add_index :cv_search_access_durations, :client_token
  end
end
