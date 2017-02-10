class MacDaxtraUser < ActiveRecord::Base
  serialize :user_profile
  serialize :registration_answers
  has_many :app_logs, as: :loggable
end
