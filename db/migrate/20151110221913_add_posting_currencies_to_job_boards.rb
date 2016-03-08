class AddPostingCurrenciesToJobBoards < ActiveRecord::Migration
  def change
    add_column :job_boards, :posting_currencies, :text
  end
end
