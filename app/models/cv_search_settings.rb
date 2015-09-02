class CvSearchSettings < ActiveRecord::Base
  belongs_to :job_board


  def cv_search_title
    self.read_attribute(:cv_search_title).present? ? self.read_attribute(:cv_search_title) : "CV Search Access"
  end
  
end