class BondAdapt::ClientService < BaseService
  attr_reader :dataset_id, :user_name, :user_url, :user_phone, :user_email
  private :dataset_id, :user_name, :user_url, :user_phone, :user_email
  
  def initialize(dataset_id, user_name = nil, user_email = nil, user_phone = nil, user_url = nil)
    @dataset_id = dataset_id
    @user_name = user_name
    @user_email = user_email
    @user_phone = user_phone
    @user_url = user_url
  end
  
  def send_to_bond_adapt(method_name)
    begin
      get_session_id
      send(method_name)
    rescue => e
      Rails.logger.info "--- Bond Adapt client exception ----- : #{e.message}"
    end
  end
  
  def create_user_request_hash      
    @create_user_request_hash_var ||= {
      'long_1' => @session_id,
      'String_2' => 'API_OJA_BasicRegistration',
      'String_3' => raw(create_user_xml)
    }
  end
  
  def raw_create_xml
    "<soapenv:Envelope xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:ns2='http://webservice.bis.com/' xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ins0='http://webservice.bis.com/types'>
          <soapenv:Body>
            <ins0:executeBO>
              <long_1>#{@session_id}</long_1>
              <String_2>API_OJA_BasicRegistration</String_2>
              <String_3>
                #{create_user_xml}
              </String_3>
            </ins0:executeBO>
          </soapenv:Body>
      </soapenv:Envelope>"
  end
  
  def create_user_xml
    "<![CDATA[
          <OJABasicReg>
            <PersonName>#{user_name}</PersonName>
            <PersonEmail>#{user_email}</PersonEmail>
            <PersonMobile>#{user_phone}</PersonMobile>
            <PersonLinkedIn>#{user_url}</PersonLinkedIn>
          </OJABasicReg>
    ]]>"
  end
  
  private
  
    def create_user
      if create_user_response_body.present?
       create_user_response_body.inspect
      else 
        nil
      end
    end 
    
    def settings
      @settings_var ||= BondAdaptAppSetting.find_by(dataset_id: dataset_id)
    end
    
    def create_user_response_body
      @create_response_body_var ||= create_user_response.body[:execute_bo_response][:result][:found_entities]
    end
    
    def create_user_response
      @create_user_response_var ||= create_user_client.call(:execute_bo, xml: raw_create_xml)
    end
    
    def create_user_client
      @create_user_client_var ||= Savon.client(
        log_level: :debug,
        log: true,
        logger: Rails.logger,
        env_namespace: :soapenv,
        pretty_print_xml: true,
        endpoint: "#{settings.endpoint}/BOExecServiceV1",
        wsdl: "#{settings.endpoint}/BOExecServiceV1?wsdl"
      )
    end
    
    def get_session_id
      client = Savon.client(
        log_level: :debug,
        log: true,
        logger: Rails.logger,
        env_namespace: :soapenv,
        pretty_print_xml: true,
        endpoint: "#{settings.endpoint}/LogonServiceV1",
        wsdl: "#{settings.endpoint}/LogonServiceV1?wsdl")
      response = client.call(:logon, message: auth_hash)
      Rails.logger.info "--- Savon response: #{response.to_xml}"
      @session_id = response.body[:logon_response][:result]
    rescue => e
      Rails.logger.info "--- Bond Adapt get_session_id exception ----- : #{e.message}"
    end
    
    def find_user_id(email)
      client = Savon.client(
        log_level: :debug,
        log: true,
        logger: Rails.logger,
        env_namespace: :soapenv,
        pretty_print_xml: true,
        endpoint: "#{settings.endpoint}/SearchServiceV1",
        wsdl: "#{settings.endpoint}/SearchServiceV1?wsdl")
    
      request_hash = {
        'long_1' => @session_id,
        'String_2' => 'ContactSearch',
        'arrayOfSearchParameter_3' => {
          'dataType' => 1,
          'dateValue' => '',
          'longValue' => '',
          'name' => 'EMAIL',
          'stringValue' => email },
        'long_4' => 1,
        'long_5' => 5,
        'boolean_6' => 0,
        'String_7' => ''
      }
      response = client.call(:run_query, message: request_hash)
      response.body[:run_query_response][:result][:found_entities].present? ? response.body[:run_query_response][:result][:found_entities].first : nil
    end



    def update_user(uid, attributes)
    end

    def auth_hash
      {
        'String_1' => settings.username,
        'String_2' => settings.password,
        'String_3' => settings.domain,
        'String_4' => settings.domain_profile,
        'String_5' => '',
        'String_6' => '',
        'int_7' => 0,
        'int_8' => 0 
      }
    end

end