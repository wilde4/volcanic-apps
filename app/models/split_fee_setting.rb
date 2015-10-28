class SplitFeeSetting < ActiveRecord::Base
  before_validation :set_defaults, on: :create

  def set_defaults
    
  end
end