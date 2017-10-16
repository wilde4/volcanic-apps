class DataImport::Line < ActiveRecord::Base
  belongs_to :file, class_name: "DataImport::File", foreign_key: "data_import_file_id"

  serialize :values

  def error_messages_hash
    @error_messages_hash ||= JSON.parse(error_messages)['response'] if error_messages.present?
  end
end
