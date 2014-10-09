class MacDaxtraUser < ActiveRecord::Base
  serialize :user_profile
  serialize :registration_answers
end
