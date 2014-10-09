class CreateMacDaxtraJobs < ActiveRecord::Migration
  def change
    create_table :mac_daxtra_jobs do |t|
      t.integer :job_id
      t.text :job
      t.string :job_type
      t.text :disciplines

      t.timestamps
    end
    add_index :mac_daxtra_jobs, :job_id
  end
end
