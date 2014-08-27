if @user.extra["user_type"] == 'graduate'
  json.matches @matches do |l|
    json.id l.id
    json.user LikesUser.find_by(user_id: l.user_id).to_builder
    json.response l.extra
  end
end

if @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
  json.matches @matches do |l|
    json.id l.id
    json.user LikesUser.find_by(user_id: l.user_id).to_builder
    json.response l.extra
  end
end