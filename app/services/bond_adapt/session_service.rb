class BondAdapt::SessionService < BaseService
  attr_reader :dataset_id
  private :dataset_id
  
  def initialize(dataset_id)
    @dataset_id = dataset_id
  end
  
  def get_session_id
    client = Savon.client(
      log_level: :debug,
      log: true,
      logger: Rails.logger,
      open_timeout: 25,
      read_timeout: 25,
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

  def settings
    @settings_var ||= BondAdaptAppSetting.find_by(dataset_id: dataset_id)
  end

private

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