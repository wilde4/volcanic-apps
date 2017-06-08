class ReedMapping < ActiveRecord::Base
  belongs_to :reed_country

  validates :discipline_id, :job_function_id, presence: true

  def job_function_name_from_api_response(job_functions)
    job_function = job_functions.find { |job_function| job_function['id'] == job_function_id }
    job_function.present? ? job_function['name'] : 'Unknown Job Function'
  end
end