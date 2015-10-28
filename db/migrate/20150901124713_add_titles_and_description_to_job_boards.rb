class AddTitlesAndDescriptionToJobBoards < ActiveRecord::Migration
  def change
    add_column :job_boards, :job_token_title, :string
    add_column :job_boards, :job_token_description, :text
    add_column :job_boards, :cv_search_title, :string
    add_column :job_boards, :cv_search_description, :text
  end
end
