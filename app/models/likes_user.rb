class LikesUser < ActiveRecord::Base
  serialize :extra, JSON
  serialize :registration_answers, JSON

  validates :user_id, uniqueness: true

  def to_builder
    Jbuilder.new do |user|
      user.id user_id
      user.first_name first_name
      user.last_name last_name
      user.avatar_url extra["avatar_path"]
      user.registration_answers registration_answers
    end
  end

end
