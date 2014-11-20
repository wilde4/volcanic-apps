class FeaturedJob < ActiveRecord::Base
  serialize :extra, JSON

  validates :job_id, uniqueness: true

  scope :by_dataset, -> id { where(dataset_id: id) }
  scope :featured, -> { where("? BETWEEN feature_start AND feature_end", DateTime.now).take }

  def self.next_available_date(dataset_id)
    last_expiry_date = self.by_dataset(dataset_id)
                           .sort_by{|j| j.feature_end || Date.new(0000) }
                           .last.feature_end

    (last_expiry_date.blank? or last_expiry_date < Date.today) ? Date.today : last_expiry_date + 1.day
  end
end