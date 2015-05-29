class ArithonUser < ActiveRecord::Base
  serialize :user_data, JSON
  serialize :user_profile, JSON
  serialize :registration_answers, JSON
  serialize :linkedin_profile, JSON

  validate :user_id, :email, presence: true
  validates :user_id, uniqueness: true
end
