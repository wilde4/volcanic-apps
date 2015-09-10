class SplitUpJobBoardTable < ActiveRecord::Migration
  def change
    create_table :job_token_settings do |t|
      t.integer :job_board_id
      t.boolean :charge_for_jobs
      t.boolean :require_tokens_for_jobs
      t.decimal :job_token_price, :precision => 8, :scale => 2
      t.string :job_token_title
      t.text :job_token_description
      t.integer :job_duration
    end

    create_table :cv_search_settings do |t|
      t.integer :job_board_id
      t.boolean :charge_for_cv_search
      t.boolean :require_access_for_cv_search
      t.decimal :cv_search_price, :precision => 8, :scale => 2
      t.integer :cv_search_duration
      t.string :cv_search_title
      t.text :cv_search_description
    end
  end
end
