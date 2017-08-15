module DataImportHelper

  def mappings_collection
    collection = []
    RegistrationQuestion.where(user_group_id: @file.user_group_id).each { |q| collection << [q.label, q.id] unless %w(password password_confirmation terms_and_conditions).include? q.core_reference }
    collection << ['Created at', 'created_at']
    collection.sort
  end

  def client_columns_collection
    [:name, :body, :logo_url, :url, :email, :phone_number, :disciplines, :address1, :address2, :address3, :address4, :address5, :location, :key_locations, :secondary_key_locations, :tag_list, :display, :active, :suspended].sort
  end

  def job_columns_collection
    ['job_title', 'job_type', 'discipline', 'job_reference',
    'job_description', 'application_email', 'application_url',
    'created_at', 'paid', 'job_location', 'salary_free', 'salary_low',
    'salary_high', 'salary_currency', 'job_startdate',
    'extra', 'expiry_date', 'job_functions', 'contact_name', 'contact_email'].sort
  end

  def blog_columns_collection
    [:title, :body, :publish_date, :source_url].sort
  end
end