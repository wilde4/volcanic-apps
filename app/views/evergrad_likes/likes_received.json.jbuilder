if @user.extra["user_type"] == 'graduate'
  json.likes @likes do |l|
    json.id l.id
    json.user LikesUser.find_by(user_id: l.user_id).to_builder
    json.response l.extra
  end
end

if @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
  json.likes @likes do |l|
    json.id l.id
    json.user LikesUser.find_by(user_id: l.user_id).to_builder
    json.liked LikesJob.find_by(job_id: l.likeable_id).to_builder
    json.response l.extra
  end
end