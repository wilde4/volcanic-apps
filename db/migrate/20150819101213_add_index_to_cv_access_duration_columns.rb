class AddIndexToCvAccessDurationColumns < ActiveRecord::Migration
  def change
    add_index :cv_search_access_durations, :app_dataset_id
    add_index :cv_search_access_durations, :user_token
  end
end
