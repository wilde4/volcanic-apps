class YuTalentAppSetting < ActiveRecord::Base

  serialize :access_token
  validates :dataset_id, presence: true

end
