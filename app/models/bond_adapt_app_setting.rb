class BondAdaptAppSetting < ActiveRecord::Base

  validates :dataset_id, presence: true

end
