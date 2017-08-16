class DataImport::Line < ActiveRecord::Base
  belongs_to :file, class_name: "DataImport::File", foreign_key: "data_import_file_id"

  serialize :values
end
