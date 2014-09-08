if @user.extra["user_type"] == 'graduate'
  json.likes @likes do |l|
    json.id l.id
    json.user LikesUser.find_by(user_id: l.user_id).to_builder
    json.response l.extra
  end
end

if @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
  json.jobs @jobs do |job|
    json.job_id job.job_id
    json.job_title job.job_title
    json.job_reference job.job_reference
    json.extra job.extra
    json.likes LikesLike.where(likeable_type: 'Job', likeable_id: job.job_id, match: false) do |l|
      json.id l.id
      json.user LikesUser.find_by(user_id: l.user_id).to_builder
      json.response l.extra
    end
  end
end