class CreateLikesJobs < ActiveRecord::Migration
  def change
    create_table :likes_jobs do |t|
      t.integer :job_id, index: true
      t.string :job_reference
      t.string :job_title
      t.integer :user_id
      t.string :cached_slug

      t.timestamps
    end
  end
end
