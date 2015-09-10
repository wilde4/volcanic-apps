class AddJobDurationToJobBoards < ActiveRecord::Migration
  def change
    add_column :job_boards, :job_duration, :integer
  end
end
