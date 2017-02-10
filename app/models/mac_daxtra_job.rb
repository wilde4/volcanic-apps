class MacDaxtraJob < ActiveRecord::Base
  serialize :job
  serialize :disciplines
  has_many :app_logs, as: :loggable
end

