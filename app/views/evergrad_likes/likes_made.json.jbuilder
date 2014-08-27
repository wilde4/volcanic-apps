json.likes @likes do |l|
  json.id l.id
  json.user_id l.user_id
  json.liked_type l.likeable_type
  if l.likeable_type == 'User'
    json.liked LikesUser.find_by(user_id: l.likeable_id).to_builder
  elsif l.likeable_type == 'Job'
    json.liked LikesJob.find_by(job_id: l.likeable_id).to_builder
  end
  json.response l.extra
end