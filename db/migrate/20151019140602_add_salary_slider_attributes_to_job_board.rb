class AddSalarySliderAttributesToJobBoard < ActiveRecord::Migration
  def change
    add_column :job_boards, :salary_min, :integer
    add_column :job_boards, :salary_max, :integer
    add_column :job_boards, :salary_step, :integer
    add_column :job_boards, :salary_from, :integer
    add_column :job_boards, :salary_to, :integer
  end
end
