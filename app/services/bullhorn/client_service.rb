class Bullhorn::ClientService < BaseService

  def initialize(bullhorn_setting)
    @bullhorn_setting = bullhorn_setting
    @client = setup_client
    @key = Key.find_by(app_dataset_id: bullhorn_setting.dataset_id, app_name: 'bullhorn')
  end

  def client_authenticated? 
    if @bullhorn_setting.auth_settings_filled
      candidates = @client.candidates(fields: 'id', sort: 'id') #TEST CALL TO CHECK IF INDEED WE HAVE PERMISSIONS (GET A CANDIDATES RESPONSE)
      
      candidates.data.size > 0
    else
      false
    end

  rescue
    false
  end

  def setup_client
    return Bullhorn::Rest::Client.new(
      username: @bullhorn_setting.bh_username,
      password: @bullhorn_setting.bh_password,
      client_id: @bullhorn_setting.bh_client_id,
      client_secret: @bullhorn_setting.bh_client_secret
    )
  end

  def bullhorn_candidate_fields

    path = "meta/Candidate"
    client_params = {fields: '*'}
    @client.conn.options.timeout = 50 # Oliver will reap a unicorn process if it's waiting for longer than 60 seconds, so we'll only wait for 50

    res = @client.conn.get path, client_params
    obj = @client.decorate_response JSON.parse(res.body)
    create_log(@bullhorn_setting, @key, 'get_bullhorn_candidate_fields', path, client_params.to_s, obj.to_s, obj.errors.present?)

    @bullhorn_fields = obj['fields'].select { |f| f['type'] == "SCALAR" }.map { |field| ["#{field['label']} (#{field['name']})", field['name']] }

    # Get nested address fields
    address_fields = obj['fields'].select { |f| f.dataType == 'Address' }
    address_fields.each do |address_field|
      if address_field['name'] == 'address'
        address_field.fields.select { |f| f['type'] == "SCALAR" }.each { |field| @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] }
      end
    end

    # Get some specfic non SCALAR fields
    obj['fields'].select { |f| f['type'] == "TO_ONE" && f['name'] == 'category' }.each { |field| @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] }
    obj['fields'].select { |f| f['type'] == "TO_MANY" && f['name'] == 'businessSectors' }.each { |field| @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] }

    @bullhorn_fields.sort! { |x,y| x.first <=> y.first }

    @bullhorn_fields
  rescue StandardError => e 
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_bullhorn_candidate_fields', nil, nil, e.message, true, true)
  end

  def volcanic_candidate_fields
    url = Rails.env.development? ? "#{@key.protocol}#{@key.host}:3000/api/v1/user_groups.json" : "#{@key.protocol}#{@key.host}/api/v1/user_groups.json"
    response = HTTParty.get(url)

    @volcanic_fields = {}
    response.each { |r| r['registration_question_groups'].each { |rg| rg['registration_questions'].each { |q| @volcanic_fields[q["reference"]] = q["label"] unless %w(password password_confirmation terms_and_conditions).include?(q['core_reference']) } } }
    @volcanic_fields = Hash[@volcanic_fields.sort]

    @volcanic_fields
  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_volcanic_candidate_fields', nil, nil, e.message, true, true)
  end

  def create_log(loggable, key, name, endpoint, message, response, error = false, internal = false)
    log = loggable.app_logs.create key: key, endpoint: endpoint, name: name, message: message, response: response, error: error, internal: internal
    log.id
  rescue StandardError => e
    Honeybadger.notify(e)
  end


  def get_fields(dataset_id)
    
    # Get bullhorn candidate fields
    client = authenticate_client(dataset_id)
    path = "meta/Candidate"
    client_params = {fields: '*'}
    client.conn.options.timeout = 50 # Oliver will reap a unicorn process if it's waiting for longer than 60 seconds, so we'll only wait for 50
    res = client.conn.get path, client_params
    obj = client.decorate_response JSON.parse(res.body)
    create_log(@bullhorn_setting, @key, 'get_fields', path, client_params.to_s, obj.to_s, obj.errors.present?)
    @bullhorn_fields = obj['fields'].select { |f| f['type'] == "SCALAR" }.map { |field| ["#{field['label']} (#{field['name']})", field['name']] }

    # Get nested address fields
    address_fields = obj['fields'].select { |f| f.dataType == 'Address' }
    address_fields.each do |address_field|
      if address_field['name'] == 'address'
        address_field.fields.select { |f| f['type'] == "SCALAR" }.each { |field| @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] }
      end
    end

    # Get some specfic non SCALAR fields
    obj['fields'].select { |f| f['type'] == "TO_ONE" && f['name'] == 'category' }.each { |field| @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] }
    obj['fields'].select { |f| f['type'] == "TO_MANY" && f['name'] == 'businessSectors' }.each { |field| @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] }

    @bullhorn_fields.sort! { |x,y| x.first <=> y.first }

    # Get bullhorn job fields
    path = "meta/JobOrder"
    res = client.conn.get path, client_params
    obj = client.decorate_response JSON.parse(res.body)
    @bullhorn_job_fields = obj['fields'].select { |f| f['type'] == "SCALAR" }.map { |field| ["#{field['label']} (#{field['name']})", field['name']] }.sort! { |x,y| x.first <=> y.first }


    # Get volcanic fields
    url = Rails.env.development? ? "#{@key.protocol}#{@key.host}:3000/api/v1/user_groups.json" : "#{@key.protocol}#{@key.host}/api/v1/user_groups.json"
    response = HTTParty.get(url)

    @volcanic_fields = {}
    response.each { |r| r['registration_question_groups'].each { |rg| rg['registration_questions'].each { |q| @volcanic_fields[q["reference"]] = q["label"] unless %w(password password_confirmation terms_and_conditions).include?(q['core_reference']) } } }
    @volcanic_fields = Hash[@volcanic_fields.sort]

    @volcanic_fields.each do |reference, label|
      @bullhorn_setting.bullhorn_field_mappings.build(registration_question_reference: reference) unless @bullhorn_setting.bullhorn_field_mappings.find_by(registration_question_reference: reference)
    end

    @volcanic_job_fields = {'salary_high' => 'Salary (High)', 'salary_free' => "Salary Displayed"}
  rescue StandardError => e # Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Net::ReadTimeout, Faraday::TimeoutError, JSON::ParserError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_fields', nil, nil, e.message, true, true)
  end


end