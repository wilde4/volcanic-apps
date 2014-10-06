class AppSetting < ActiveRecord::Base
  serialize :settings
  
  validates :dataset_id, presence: true
end