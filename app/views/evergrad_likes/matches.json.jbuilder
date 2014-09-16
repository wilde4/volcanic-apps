if @user.extra["user_type"] == 'graduate'
  json.matches @matches do |l|
    json.id l.id
    json.user LikesUser.find_by(user_id: l.user_id).to_builder
    json.liked LikesJob.find_by(job_id: l.likeable_id).to_builder
    json.response l.extra
  end
  json.total_matches @matches.count
end

match_count = 0
if @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
  json.jobs @jobs do |job|
    json.job_id job.job_id
    json.job_title job.job_title
    json.job_reference job.job_reference
    json.extra job.extra
    json.paid job.paid
    json.likes LikesLike.where(likeable_type: 'Job', likeable_id: job.job_id, match: true).to_a.uniq{|m| m.user_id} do |l|
      json.id l.id
      json.user LikesUser.find_by(user_id: l.user_id).to_builder
      json.response l.extra
      match_count += 1
    end
  end
  json.total_matches match_count
end