class RemoveUnusedColumns < ActiveRecord::Migration
  def change
    remove_column :job_boards, :charge_for_jobs
    remove_column :job_boards, :require_tokens_for_jobs
    remove_column :job_boards, :job_token_price
    remove_column :job_boards, :job_token_title
    remove_column :job_boards, :job_token_description
    remove_column :job_boards, :job_duration

    remove_column :job_boards, :charge_for_cv_search
    remove_column :job_boards, :require_access_for_cv_search
    remove_column :job_boards, :cv_search_price
    remove_column :job_boards, :cv_search_duration
    remove_column :job_boards, :cv_search_title
    remove_column :job_boards, :cv_search_description
  end
end
