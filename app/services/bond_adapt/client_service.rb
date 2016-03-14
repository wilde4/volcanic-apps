class BondAdapt::ClientService < BaseService
  attr_reader :dataset_id, :user_name, :user_url, :user_phone, :user_email, :user_url, :user_location, :user_sector,:user_permanent, :user_contract
  private :dataset_id, :user_name, :user_url, :user_phone, :user_email, :user_url, :user_location, :user_sector, :user_permanent, :user_contract
  
  def initialize(args)
    @dataset_id = args[:dataset_id]
    @user_name = args[:user_name]
    @user_email = args[:user_email]
    @user_phone = args[:user_phone]
    @user_url = args[:user_url]
    @user_location = args[:user_location]
    @user_sector = args[:user_sector]
    @user_permanent = args[:user_permanent]
    @user_contract = args[:user_contract]
  end
  
  def send_to_bond_adapt(method_name)
    @method_name = method_name
    begin
      if @method_name.include?("create_user")
        get_session_id
        create_user
      end
    rescue => e
      Rails.logger.info "--- Bond Adapt client exception ----- : #{e.message}"
    end
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
    
    def raw_create_xml
      "<soapenv:Envelope xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:ns2='http://webservice.bis.com/' xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ins0='http://webservice.bis.com/types'>
            <soapenv:Body>
              <ins0:executeBO>
                <long_1>#{@session_id}</long_1>
                <String_2>#{choose_end_point}</String_2>
                <String_3>
                  #{create_user_xml}
                </String_3>
                #{add_full_reg_stuff?}
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
            #{add_full_feilds?}
          </OJABasicReg>
      ]]>"
    end
  
    def add_full_feilds?
      if @method_name == "create_user_full_reg"
        "<PersonLocation>#{user_location}</PersonLocation>
        <PersonSector>#{user_sector}</PersonSector>
        <PersonPermanent>#{user_permanent}</PersonPermanent>
        <PersonContract>#{user_contract}</PersonContract>"
      else
        ""
      end
    end
    
    def add_full_reg_stuff?
      if @method_name == "create_user_full_reg"
        "<arrayOfControlValue_4>
              <controlPath>?</controlPath>
              <dataType>?</dataType>
              <name>?</name>
              <value>?</value>
           </arrayOfControlValue_4>"
      else
        ""
      end
    end
    
    def choose_end_point
      if @method_name == "create_user" 
        "API_OJA_BasicRegistration"
      elsif @method_name == "create_user_full_reg" 
        "API_OJA_CandidateRegistration"
      end
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
    
    # def find_user_id(email)
    #   client = Savon.client(
    #     log_level: :debug,
    #     log: true,
    #     logger: Rails.logger,
    #     env_namespace: :soapenv,
    #     pretty_print_xml: true,
    #     endpoint: "#{settings.endpoint}/SearchServiceV1",
    #     wsdl: "#{settings.endpoint}/SearchServiceV1?wsdl")
    #
    #   request_hash = {
    #     'long_1' => @session_id,
    #     'String_2' => 'ContactSearch',
    #     'arrayOfSearchParameter_3' => {
    #       'dataType' => 1,
    #       'dateValue' => '',
    #       'longValue' => '',
    #       'name' => 'EMAIL',
    #       'stringValue' => email },
    #     'long_4' => 1,
    #     'long_5' => 5,
    #     'boolean_6' => 0,
    #     'String_7' => ''
    #   }
    #   response = client.call(:run_query, message: request_hash)
    #   response.body[:run_query_response][:result][:found_entities].present? ? response.body[:run_query_response][:result][:found_entities].first : nil
    # end

    # def create_user_request_hash
    #   @create_user_request_hash_var ||= {
    #     'long_1' => @session_id,
    #     'String_2' => 'API_OJA_BasicRegistration',
    #     'String_3' => raw(create_user_xml)
    #   }
    # end

    # def update_user(uid, attributes)
    # end

end