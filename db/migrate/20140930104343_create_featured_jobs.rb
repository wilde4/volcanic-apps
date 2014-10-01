class CreateFeaturedJobs < ActiveRecord::Migration
  def change
    create_table :featured_jobs do |t|
      t.integer :job_id, index: true
      t.integer :user_id
      t.integer :dataset_id
      t.string :job_reference
      t.string :job_title
      t.text :extra
      t.date :feature_start
      t.date :feature_end
    end
  end
end
