class CreateJobBoards < ActiveRecord::Migration
  def change
    create_table :job_boards do |t|
      t.integer :app_dataset_id
      t.boolean :charge_for_jobs
      t.decimal :job_token_price, :precision => 8, :scale => 2
      t.boolean :charge_for_cv_search
      t.decimal :cv_search_price, :precision => 8, :scale => 2
      t.integer :cv_search_duration

      t.timestamps
    end
    add_index :job_boards, :app_dataset_id
  end
end
