class JobAdderController < ApplicationController
  
    
  protect_from_forgery with: :null_session
  respond_to :xml

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]
  before_action :set_xml, :set_key_jobs, :check_api_access, only: [:capture_jobs]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    render layout: false
  end

  def capture_jobs
    @xml.search('//Job').each do |job|
      disciplines_ids_arr = find_disciplines(job.search('Classification[name="Categories"]'))
      @options = {
        job: 
          { api_key: @key.api_key, 
            salary_low:  job.search('MinValue').text,
            salary_high:  job.search('MaxValue').text,
            salary_benefits: job.search('Text').text,
            salary_free: build_salary_free(job),
            salary_currency: job.search('Classification[name="Currency"]').text,
            job_location: build_location(job), 
            job_reference: job.attr('reference'), 
            job_description: build_description(job), 
            job_title: job.search('Title').text, 
            job_type: find_job_type(job.search('Classification[name="Job Type"]').text),
            application_email: job.search('EmailTo').text,
            application_url: job.search('Url').text,
            discipline: disciplines_ids_arr.join(",") 
          }
      }
      if Rails.env.development?
        @jobs_responce = HTTParty.post("http://workmates.localhost.volcanic.co:3000/api/v1/jobs.json", { body: @options })
      else
        @jobs_responce = HTTParty.post("http://#{@key.host}/api/v1/jobs.json", { body: @options })
      end
    end
  end

  private

  def build_location(job)
    location = [job.search('Classification[name="Location"]').text]
    location << job.search('Classification[name="Sub-Location"]').text
    location.reject { |l| l.blank? }.join(', ')
  end
  
  def build_salary_free(job)
    if job.search('Salary').present?
      "#{job.search('MinValue').text} to #{job.search('MaxValue').text} #{job.search('Salary').attr('period')} #{job.search('Text').text}" rescue nil
    end
  end
  
  def build_description(job)
    description = job.search('Description').text 
    if job.search('BulletPoint').present?
      description = description + "</br><ul>"
      job.search('BulletPoint').each do |bp|
        description = description + "<li>#{bp.text}</li>"
      end
      description = description + "</ul>"
    end
    description
  end
  
  def find_disciplines(job_adder_categories)
    arr = []
    if Rails.env.development?
      disciplines_response =  HTTParty.get("http://workmates.localhost.volcanic.co:3000/api/v1/disciplines.json?")
    else
      disciplines_response =  HTTParty.get("http://#{@key.host}/api/v1/disciplines.json?")
    end
    
    parsed_disciplines_response = JSON.parse(disciplines_response.body)
    job_adder_categories.each do |category|
      if parsed_disciplines_response.find { |discipline| discipline['name'] == category.text }
        arr << parsed_disciplines_response.find { |discipline| discipline['name'] == category.text }['id']
      end
    end
    arr
  end

  def find_job_type(work_type)
    if Rails.env.development?
      job_types_response =  HTTParty.get("http://workmates.localhost.volcanic.co:3000/api/v1/job_types.json?")
    else
      job_types_response =  HTTParty.get("http://#{@key.host}/api/v1/job_types.json?")
    end
    
    parsed_job_types_response = JSON.parse(job_types_response.body)
    job_type = parsed_job_types_response.find { |job_type| job_type['reference'] == work_type }
    job_type ||= parsed_job_types_response.find { |job_type| job_type['name'] == work_type }
    job_type['reference'] unless job_type.nil?
  end
  
  
  def set_xml
    if params["jobadder.xml"].present?
      @xml = Nokogiri::XML(params["jobadder.xml"])
    else
      @xml =  Nokogiri::XML(request.body)
    end
  end
  
  def check_api_access
    head :unauthorized unless @key.present?
  end
  
  
  def set_key_jobs
    @token = @xml.search('/Jobs/@account').text 
    @key = Key.find_by(api_key: @token)
  end
  

end
  