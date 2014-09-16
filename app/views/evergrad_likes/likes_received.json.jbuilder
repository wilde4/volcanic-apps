total_likes = 0

if @user.extra["user_type"] == 'graduate'
  json.likes @likes do |l|
    json.id l.id
    json.user LikesUser.find_by(user_id: l.user_id).to_builder
    json.response l.extra
    total_likes += 1
  end
end

if @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
  json.jobs @jobs do |job|
    json.job_id job.job_id
    json.job_title job.job_title
    json.job_reference job.job_reference
    json.extra job.extra
    json.paid job.paid
    json.likes LikesLike.where(likeable_type: 'Job', likeable_id: job.job_id, match: false).to_a.uniq{|m| m.user_id} do |l|
      json.id l.id
      json.user LikesUser.find_by(user_id: l.user_id).to_builder
      json.response l.extra
      total_likes += 1
    end
  end
end

json.total_likes total_likes