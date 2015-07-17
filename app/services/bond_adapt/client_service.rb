class BondAdapt::ClientService < BaseService

  def initialize(dataset_id)
    begin
      @settings = BondAdaptAppSetting.find_by(dataset_id: dataset_id)
      @client = Savon.client(
        log_level: :debug,
        log: true,
        logger: Rails.logger,
        env_namespace: :soapenv,
        pretty_print_xml: true,
        endpoint: @settings.endpoint,
        wsdl: "#{@settings.endpoint}?wsdl")
      get_session_id
    rescue => e
      Rails.logger.info "--- Bond Adapt client exception ----- : #{e.message}"
    end
  end

  def get_session_id
    begin
      response = @client.call(:logon, message: auth_hash)
      Rails.logger.info "--- Savon response: #{response.to_xml}"
      @session_id = response.body[:logon_response][:result]
    rescue => e
      Rails.logger.info "--- Bond Adapt get_session_id exception ----- : #{e.message}"
    end
  end

  def client
    @client
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