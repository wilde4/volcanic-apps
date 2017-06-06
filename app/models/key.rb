class Key < ActiveRecord::Base
  has_many :app_logs

  validates :app_dataset_id, uniqueness: { scope: :app_name}

  def as_json(options = {})
    {
      api_key: api_key,
      app_name: app_name
    }
  end
end