class Profile < ActiveRecord::Base

  devise :database_authenticatable

  has_many :data_import_files, class_name: 'DataImport::File'
  has_many :registration_questions

  validates :host, presence: true, uniqueness: true
  validates :app_dataset_id, presence: true, uniqueness: true


  def encrypted_password
    []
  end

end
