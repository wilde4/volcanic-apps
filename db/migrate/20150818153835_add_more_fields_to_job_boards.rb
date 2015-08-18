class AddMoreFieldsToJobBoards < ActiveRecord::Migration
  def change
    add_column :job_boards, :require_tokens_for_jobs, :boolean
    add_column :job_boards, :require_access_for_cv_search, :boolean
  end
end
