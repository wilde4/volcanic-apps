class CreateBullhornJobs < ActiveRecord::Migration
  def change
    create_table :bullhorn_jobs do |t|
      t.references :key, index: true
      t.integer :bullhorn_uid
      t.text :job_params
      t.boolean :error, default: false

      t.timestamps
    end
  end
end
