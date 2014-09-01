class LikesJob < ActiveRecord::Base
  serialize :extra, JSON

  validates :job_id, uniqueness: true

  scope :live, -> { where('expiry_date > ?', Date.today) }

  def to_builder
    Jbuilder.new do |job|
      job.id job_id
      job.job_reference job_reference
      job.job_title job_title
      job.extra extra
      job.user LikesUser.find_by(user_id: user_id).to_builder
    end
  end

end
