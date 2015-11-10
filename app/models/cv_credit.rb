class CvCredit < ActiveRecord::Base
  validates_presence_of :client_token

end