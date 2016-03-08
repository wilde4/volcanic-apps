class CreateCvSearchAccessDurations < ActiveRecord::Migration
  def change
    create_table :cv_search_access_durations do |t|
      t.integer :app_dataset_id
      t.string :user_token
      t.integer :duration_added
      t.datetime :expiry_date

      t.timestamps
    end
  end
end
