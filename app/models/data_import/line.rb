class DataImport::Line < ActiveRecord::Base
  belongs_to :file, class_name: "DataImport::File", foreign_key: "data_import_file_id"

  serialize :values

  scope :errors, -> { where(error: true) }

  def error_messages_hash
    @error_messages_hash ||= JSON.parse(error_messages)['response'] if error_messages.present?
  end

  def error_message
    case file.model
    when 'redirect'
      error_messages_hash['reason']
    else
      error_messages_hash['errors']
    end
  end
end
