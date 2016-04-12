class IndexFeaturedJobsOnJobId < ActiveRecord::Migration
  def change
    add_index :featured_jobs, :job_id
  end
end
