class AppLog < ActiveRecord::Base
  belongs_to :key
  belongs_to :loggable, polymorphic: true

  def as_json(options = {})
    {
      key: (key.present? ? key.as_json : {}),
      loggable_type: loggable_type,
      error: error,
      internl: internal,
      created_at: created_at
    }
  end
end