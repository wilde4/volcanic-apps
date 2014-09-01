class LikesLike < ActiveRecord::Base
  belongs_to :user, class_name: 'LikesUser', foreign_key: 'user_id'

  serialize :extra

  validates :like_id, uniqueness: true

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ['Employer', 'Job Title', 'Job Reference', 'Graduate', 'Match?', 'Created Date']
      all.each do |like|
        @job = LikesJob.find_by(job_id: like.likeable_id)
        job_title = @job.job_title rescue 'No Job Found'
        job_reference = @job.job_reference rescue 'No Job Found'
        employer = LikesUser.find_by(user_id: @job.user_id).registration_answers["company-name"]
        @grad = LikesUser.find_by(user_id: like.user_id)
        grad_name = "#{@grad.first_name} #{@grad.last_name}" rescue 'No User Found'
        csv << [employer, job_title, job_reference, grad_name, like.match, like.created_at.to_s(:db)]
      end
    end
  end

end
