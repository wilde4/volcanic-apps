class LikesLike < ActiveRecord::Base
  belongs_to :user, class_name: 'LikesUser', foreign_key: 'user_id'

  serialize :extra

  validates :like_id, uniqueness: true
end
