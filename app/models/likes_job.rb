class LikesJob < ActiveRecord::Base
  validates :job_id, uniqueness: true

  def to_builder
    Jbuilder.new do |job|
      job.id job_id
      job.job_reference job_reference
      job.job_title job_title
      job.cached_slug cached_slug
      job.user LikesUser.find_by(user_id: user_id).to_builder
    end
  end

end
