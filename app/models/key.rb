class Key < ActiveRecord::Base
  validates :app_dataset_id, uniqueness: { scope: :app_name}
end