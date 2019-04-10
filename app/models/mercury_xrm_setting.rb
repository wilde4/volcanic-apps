class MercuryXrmSetting < ActiveRecord::Base
  serialize :settings, Hash
end
