class JobAdderController < ApplicationController
  
    
  protect_from_forgery with: :null_session
  respond_to :xml

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]
  before_action :check_api_access, only: [:capture_jobs]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
  end

  def capture_jobs
    # @key = Key.where(app_name: 'job_adder').last
    @xml = Nokogiri::XML(request.body)
    @xml.search('//Job').each do |job|
      disciplines_ids_arr = find_disciplines(job.search('Classification[name="Category"]')).concat(find_disciplines(job.search('Classification[name="Sub Category"]')))
      @options = {
        job: 
          { api_key: @key.api_key, 
            salary_low:  job.search('MinValue').text,
            salary_high:  job.search('MaxValue').text,
            salary_benefits: job.search('Text').text,
            salary_free: build_salary_free(job),
            salary_currency: "AUD",
            job_location: job.search('Classification[name="Location"]').text, 
            job_reference: job.attr('reference'), 
            job_description: build_description(job), 
            job_title: job.search('Title').text, 
            job_type: "permanent", 
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
  
  def build_salary_free(job)
    "#{job.search('MinValue').text} to #{job.search('MaxValue').text} #{job.search('Salary').attr('period')} #{job.search('Text').text}"
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
      disciplines_responce =  HTTParty.get("http://workmates.localhost.volcanic.co:3000/api/v1/disciplines.json?", { body: { api_key: @key.api_key } })
    else
      disciplines_responce =  HTTParty.get("http://#{@key.host}/api/v1/disciplines.json?", { body: { api_key: @key.api_key } })
    end
    
    parsed_disciplines_responce = JSON.parse(disciplines_responce.body)
    job_adder_categories.each do |category|
      if parsed_disciplines_responce.find { |discipline| discipline['name'] == category.text }
        arr << parsed_disciplines_responce.find { |discipline| discipline['name'] == category.text }['id']
      end
    end
    arr
  end

  def check_api_access
    authenticate_or_request_with_http_token do |token, options|
      if Key.find_by(api_key: token)
        @key = Key.find_by(api_key: token)
      end
    end
  end

end
  