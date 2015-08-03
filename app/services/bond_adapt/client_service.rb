class BondAdapt::ClientService < BaseService

  def initialize(dataset_id)
    begin
      @settings = BondAdaptAppSetting.find_by(dataset_id: dataset_id)
      get_session_id
    rescue => e
      Rails.logger.info "--- Bond Adapt client exception ----- : #{e.message}"
    end
  end

  def get_session_id
    client = Savon.client(
      log_level: :debug,
      log: true,
      logger: Rails.logger,
      env_namespace: :soapenv,
      pretty_print_xml: true,
      endpoint: "#{@settings.endpoint}/LogonServiceV1",
      wsdl: "#{@settings.endpoint}/LogonServiceV1?wsdl")
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
      endpoint: "#{@settings.endpoint}/SearchServiceV1",
      wsdl: "#{@settings.endpoint}/SearchServiceV1?wsdl")
    
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

  def create_user(attributes)
  end

  def update_user(uid, attributes)
  end

  def auth_hash
    {
      'String_1' => @settings.username,
      'String_2' => @settings.password,
      'String_3' => @settings.domain,
      'String_4' => @settings.domain_profile,
      'String_5' => '',
      'String_6' => '',
      'int_7' => 0,
      'int_8' => 0 
    }
  end

end