class LikesUser < ActiveRecord::Base
  serialize :extra, JSON
  serialize :registration_answers, JSON

  validates :user_id, uniqueness: true

  def to_builder
    Jbuilder.new do |user|
      user.id user_id
      user.first_name first_name
      user.last_name last_name
      user.email email
      user.avatar_thumb_path extra["avatar_thumb_path"]
      user.avatar_medium_cropped_path extra["avatar_medium_cropped_path"]
      user.avatar_medium_uncropped_path extra["avatar_medium_uncropped_path"]
      user.avatar_large_cropped_path extra["avatar_large_cropped_path"]
      user.avatar_large_uncropped_path extra["avatar_large_uncropped_path"]
      user.registration_answers registration_answers
      user.extra extra['user_type']
    end
  end

end
