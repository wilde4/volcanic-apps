class AddSelectionLimitAttributesToJobBoards < ActiveRecord::Migration
  def change
    add_column :job_boards, :disciplines_limit, :integer, default: 0
    add_column :job_boards, :job_functions_limit, :integer, default: 0
    add_column :job_boards, :key_locations_limit, :integer, default: 0
  end
end
