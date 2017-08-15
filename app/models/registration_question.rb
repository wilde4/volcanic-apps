class RegistrationQuestion < ActiveRecord::Base
  
  belongs_to :profile
  has_many :data_import_headers, class_name: 'DataImport::Header', dependent: :nullify
  
end
