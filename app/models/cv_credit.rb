class CvCredit < ActiveRecord::Base
  validates_presence_of :client_token

  before_save :expire_if_used

  def expire_if_used
    if self.credits_spent == self.credits_added
      self.expired = true
    end
  end
end