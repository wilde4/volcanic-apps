class MailChimpAppSettings < ActiveRecord::Base
  serialize :access_token
  validates :dataset_id, presence: true
  has_many :mail_chimp_conditions
end
