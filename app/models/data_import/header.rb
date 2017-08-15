class DataImport::Header < ActiveRecord::Base
  belongs_to :file, class_name: "DataImport::File", foreign_key: "data_import_file_id"
  belongs_to :registration_question
end
