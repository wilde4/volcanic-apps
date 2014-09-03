class Key < ActiveRecord::Base
  validates :dataset_id, uniqueness: { scope: :app_name}
end