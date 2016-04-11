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
    @disciplines = HTTParty.get("#{host_endpoint}/api/v1/disciplines.json?").parsed_response
    @consultants = HTTParty.get("#{host_endpoint}/api/v1/consultants/search.json").parsed_response['consultants']
    Thread.new {
      @xml.search('//Job').each do |job|
        disciplines_ids_arr = find_disciplines(job.search('Classification[name="Categories"]'))
      
        consultant = @consultants.find { |c| c['email_address'] == job.search('EmailTo').text }
        if consultant.present?
          contact_hash = {
            contact_name: consultant['name'],
            contact_email: consultant['email_address'],
            contact_telephone: consultant['phone_number']
          }
        else
          contact_hash = {}
        end

        puts contact_hash

        @options = {
          job: 
            { api_key: @key.api_key, 
              salary_low:  job.search('MinValue').text,
              salary_high:  job.search('MaxValue').text,
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
            }.merge(contact_hash)
        }
        @jobs_responce = HTTParty.post("#{host_endpoint}/api/v1/jobs.json", { body: @options })
         logger.info "--- Job Adder Volcanic responce = #{job.present? ? job.search('Title').try(:text) : 'No Job Found'}: #{@jobs_responce.body}"
      end
    }
    render status: 200
  end

  private

  def build_location(job)
    location = [job.search('Classification[name="Location"]').text]
    location << job.search('Classification[name="Sub-Location"]').text
    location.reject { |l| l.blank? }.join(', ')
  end
  
  def build_salary_free(job)
    if job.search('Salary').present?
      job.search('Text').text rescue nil
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
    job_adder_categories.each do |category|
      if @disciplines.find { |discipline| discipline['name'] == category.text }
        arr << @disciplines.find { |discipline| discipline['name'] == category.text }['id']
      end
    end
    arr
  end

  def find_job_type(work_type)
    job_types_response = HTTParty.get("#{host_endpoint}/api/v1/job_types.json?")
        
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

  def host_endpoint
    if Rails.env.development?
      "http://workmates.localhost.volcanic.co:3000"
    else
      "http://#{@key.host}"
    end
  end
  

end
  