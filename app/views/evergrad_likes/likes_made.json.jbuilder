json.likes @likes do |l|
  @liked = LikesUser.find_by(user_id: l.likeable_id) if l.likeable_type == 'User'
  @liked = LikesJob.live.find_by(job_id: l.likeable_id) if l.likeable_type == 'Job'
  if @liked.present?
    json.id l.id
    json.user_id l.user_id
    json.liked_type l.likeable_type
    json.liked @liked.to_builder
    json.response l.extra
  end
end

json.total_likes @likes.count