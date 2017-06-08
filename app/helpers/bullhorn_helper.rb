module BullhornHelper

  def default_job_attribute(job_attribute)
    case job_attribute
    when 'job_title'
      return 'title'
    when 'discipline'
      return 'discipline_list'
    when 'job_reference'
      return 'id'
    when 'job_type'
      return 'employmentType'
    when 'salary_low'
      return 'salary'
    when 'job_description'
      return 'publicDescription'
    else
      return ''
    end
  end

end