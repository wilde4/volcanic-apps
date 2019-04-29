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
      return job_attribute
    end
  end

  def poll_collection
    [
      ['Every Hour', 1],
      ['Every 2 hours', 2],
      ['Every 3 hours', 3],
      ['Every 4 hours', 4],
      ['Every 6 hours', 6],
      ['Every 12 hours', 12],
      ['Every 24 hours', 24],
    ]
  end

end