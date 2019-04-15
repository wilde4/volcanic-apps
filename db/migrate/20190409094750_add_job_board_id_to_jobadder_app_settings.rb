class AddJobBoardIdToJobadderAppSettings < ActiveRecord::Migration
  def change
    add_column :jobadder_app_settings, :job_board_id, :integer
  end
end
