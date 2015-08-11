class JobBoard < ActiveRecord::Base
  validates_presence_of :app_dataset_id

end