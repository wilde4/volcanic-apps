class ArithonUser < ActiveRecord::Base
  has_many :app_logs, as: :loggable
  serialize :user_data, JSON
  serialize :user_profile, JSON
  serialize :registration_answers, JSON
  serialize :linkedin_profile, JSON
  serialize :legal_documents, JSON

  validate :user_id, :email, presence: true
  validates :user_id, uniqueness: true

  after_initialize :initialize_legal_documents

  def initialize_legal_documents
    self.legal_documents ||= []
  end

end