class BondAdapt::ActivityService < BaseService
  include BondAdapt::SessionMethods
  include VolcanicApiMethods
  attr_reader :dataset_id, :user_id, :user_name, :user_phone, :user_email, :app_name
  private :dataset_id, :user_id, :user_name, :user_phone, :user_email, :app_name
  
  def initialize(args)
    @dataset_id = args[:dataset_id]
    @user_id =  args[:user_id]
    @user_name = args[:user_name]
    @user_email = args[:user_email]
    @user_phone = args[:user_phone]
    @app_name = 'bond_adapt'
  end
  
  def send_activity_log
    # puts activity_string
    create_activity_log  
  rescue => e
    Rails.logger.info "--- Bond Adapt client exception ----- : #{e.message}"
  end
  
  private
  
    def create_activity_log
      if activity_log_response_body.present?
        Rails.logger.info "--- Savon create_user response: #{activity_log_response_body.inspect.to_xml}"
      else 
        nil
      end
    end
  
    def activity_log_response_body
      @activity_log_response_body ||= activity_log_response.body[:execute_bo_response][:result][:found_entities]
    end
    
    def activity_log_response
      @activity_log_response ||= activity_log_client.call(:execute_bo, xml: activity_xml)
    end
    
    def activity_log_client
      @activity_log_client ||= Savon.client(
        log_level: :debug,
        log: true,
        logger: Rails.logger,
        open_timeout: 25,
        read_timeout: 25,
        env_namespace: :soapenv,
        pretty_print_xml: true,
        endpoint: "#{settings.endpoint}/BOExecServiceV1",
        wsdl: "#{settings.endpoint}/BOExecServiceV1?wsdl"
      )
    rescue => e
      Rails.logger.info "--- Bond Adapt create_user exception ----- : #{e.message}"
    end
    
    def activity_xml
      "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:typ='http://webservice.bis.com/types'>
         <soapenv:Header/>
         <soapenv:Body>
            <typ:executeBO>
               <long_1>#{session_id}</long_1>
               <String_2>API_OJA_LogWebActivity</String_2>
               <String_3><![CDATA[
               <logWebActivityRequest><person><personName>#{user_name}</personName>
      				<personEmail>#{user_email}</personEmail>
      				<personMobile>#{user_phone}</personMobile></person><activityNotes>#{activity_string}</activityNotes>
      		</logWebActivityRequest>
               ]]>
      </String_3>
               <!--Zero or more repetitions:-->
               <arrayOfControlValue_4>
                  <controlPath>?</controlPath>
                  <dataType>?</dataType>
                  <name>?</name>
                  <value>?</value>
               </arrayOfControlValue_4>
            </typ:executeBO>
         </soapenv:Body>
      </soapenv:Envelope>"
    end
  
    def activity_string
      "JOB SEARCHES. \n" << build_string('job_searches').to_s << "\n JOB VIEWS.  \n" << build_string('job_views').to_s << "\n PAGE VIEWS.  \n" << build_string('page_views').to_s
    end
  
    def job_searches_responce_body(page)
      HTTParty.get(end_point('job_searches') << "&page=#{page}" ).body
    end
    
    def page_views_responce_body(page)
      HTTParty.get(end_point('page_views') << "&page=#{page}").body
    end
    
    def job_views_responce_body(page)
      HTTParty.get(end_point_job_views_filter_on('page_views') << "&page=#{page}" ).body
    end
    
    def build_string(records_name)
      str = ''
      json_first_page = parse_body(send("#{records_name}_responce_body".to_sym, "1"))
      if check_json?(json_first_page, 1) && pagination_is_there?(json_first_page)
        page_count(json_first_page).times do |index|
          json = parse_body(send("#{records_name}_responce_body".to_sym, page_number(index)))
          str  << process_json_to_str(json, records_name)
        end
      end
      str  
    end  
    
    def process_json_to_str(json, records_name)
      str_2 = ''
      if check_json?(json, 0)
        json[0].each_with_index do |record, index|
          str_2 << send("stringify_#{records_name}".to_sym, record, index)
        end  
      end 
      str_2
    end
    
    def stringify_job_searches(job_search, index)
      if job_search.is_a?(Hash)
        "#{index + 1}) 
        Keywords: #{job_search['query']}; 
        Location: #{job_search['location']}; 
        Results:  #{job_search['result_count']}; 
        Date: #{job_search['created_at'] } \n"
      else
        ""
      end
    end
    
    def stringify_job_views(job_views, index)
      if job_views.is_a?(Hash)
        "#{index + 1})
        Path: #{job_views['path']}; 
        Job ID: #{job_views['source_record_id']}; 
        Job Reference: #{job_views['job_reference']}; 
        Job Title:  #{job_views['job_title']}; 
        Consultant Name:  #{job_views['job_consultant_name']};
        Device:  #{job_views['device']};
        Browser: #{job_views['browser']};
        IP Address: #{job_views['ip_address']};   
        Date: #{job_views['created_at'] } \n"
      else
        ""
      end
    end
    
    def stringify_page_views(page_views, index)
      if page_views.is_a?(Hash)
        "#{index + 1})
        Path: #{page_views['path']}; 
        Device:  #{page_views['device']};
        Browser: #{page_views['browser']};
        IP Address: #{page_views['ip_address']};   
        Date: #{page_views['created_at'] } \n"
      else
        ""
      end
    end
    
    def end_point(end_point_name)
      "#{api_address}#{end_point_name}.json#{query_params}"
    end
    
    def end_point_job_views_filter_on(end_point_name)
      end_point(end_point_name) << "&source_record_type=Job"
    end
    
    def query_params
      @query_params ||= "?api_key=#{key.api_key}&user_id=#{user_id}&start_date=#{start_date}"
    end
    
    def start_date
      @start_date ||= (Time.now - 24.hours).strftime("%Y-%m-%d")
    end
end