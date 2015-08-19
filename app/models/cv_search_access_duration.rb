class CvSearchAccessDuration < ActiveRecord::Base

  validate :user_or_client_token

  protected
    def user_or_client_token
      if self.user_token.blank? && self.client_token.blank?
        errors.add(:user_token, "client or user token required")
        errors.add(:client_token, "client or user token required")
      end
    end
end