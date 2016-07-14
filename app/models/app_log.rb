class AppLog < ActiveRecord::Base
  belongs_to :key
  belongs_to :loggable, polymorphic: true
end