class SemrushAppSettings < ActiveRecord::Base
  
  has_many :semrush_stats
  
  validates :dataset_id, presence: true
  validates :request_rate, presence: true
  validates :previous_data, presence: true
  validates :engine, presence: true
  validates :domain, presence: true
  
  def dataset_stats
    semrush_stats
  end
  
  def has_records?
    semrush_stats.present?
  end
  
  def day_of_petition?
    if last_petition_at == nil
      petition = true
    else
      petition = (last_petition_at + request_rate.days) == Date.today
    end
    petition
  end
end
