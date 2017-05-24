class Bullhorn::ClientService < BaseService

  def initialize(bullhorn_setting)
    @bullhorn_setting = bullhorn_setting
    @client = setup_client
    @key = Key.find_by(app_dataset_id: bullhorn_setting.dataset_id, app_name: 'bullhorn')
  end

  # CHECK IF THE CLIENT HAVE ACCES TO THE API
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

  # GETS BULLHORN CANDIDATES FIELDS VIA API USING THE GEM
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
        address_field.fields.select { |f| f['type'] == "SCALAR" }.each { |field|
          @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']]
        }
      end
    end

    # Get some specfic non SCALAR fields
    obj['fields'].select { |f| f['type'] == "TO_ONE" && f['name'] == 'category' }.each { |field| 
      @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] 
    }
    obj['fields'].select { |f| f['type'] == "TO_MANY" && f['name'] == 'businessSectors' }.each { |field| 
      @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] 
    }

    @bullhorn_fields.sort! { |x,y| x.first <=> y.first }

    @bullhorn_fields
  rescue StandardError => e 
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_bullhorn_candidate_fields', nil, nil, e.message, true, true)
  end

  # GETS VOLCANIC CANDIDATES FIELDS VIA API
  def volcanic_candidate_fields
    url = Rails.env.development? ? "#{@key.protocol}#{@key.host}:3000/api/v1/user_groups.json" : "#{@key.protocol}#{@key.host}/api/v1/user_groups.json"
    response = HTTParty.get(url)

    @volcanic_fields = {}
    response.each { |r| 
      r['registration_question_groups'].each { |rg| 
        rg['registration_questions'].each { |q| 
          @volcanic_fields[q["reference"]] = q["label"] unless %w(password password_confirmation terms_and_conditions).include?(q['core_reference']) 
        } 
      } 
    }
    @volcanic_fields = Hash[@volcanic_fields.sort]

    @volcanic_fields
  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_volcanic_candidate_fields', nil, nil, e.message, true, true)
  end

  # GETS BULLHORN JOB FIELDS VIA API USING THE GEM
  def bullhorn_job_fields

    path = "meta/JobOrder"
    client_params = {fields: '*'}
    @client.conn.options.timeout = 50 # Oliver will reap a unicorn process if it's waiting for longer than 60 seconds, so we'll only wait for 50

    res = @client.conn.get path, client_params
    obj = @client.decorate_response JSON.parse(res.body)
    create_log(@bullhorn_setting, @key, 'get_bullhorn_job_fields', path, client_params.to_s, nil, obj.errors.present?)

    @bullhorn_job_fields = obj['fields'].select { |f| f['type'] == "SCALAR" }.map { |field| ["#{field['label']} (#{field['name']})", field['name']] }.sort! { |x,y| x.first <=> y.first }

    @bullhorn_job_fields

  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_bullhorn_job_fields', nil, nil, e.message, true, true)
  end

  # GETS VOLCANIC JOB FIELDS VIA API
  def volcanic_job_fields
    
    url = Rails.env.development? ? "#{@key.protocol}#{@key.host}:3000/api/v1/available_job_attributes.json?api_key=#{@key.api_key}" : "#{@key.protocol}#{@key.host}/api/v1/available_job_attributes.json?api_key={@key.api_key}"
    response = HTTParty.get(url)

    @volcanic_job_fields = {}

    response.each { |r, val| 
      @volcanic_job_fields[val['attribute']] = val['name'] 
    }

    # @volcanic_job_fields = Hash[@volcanic_job_fields.sort]

    @volcanic_job_fields

  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_volcanic_job_fileds', nil, nil, e.message, true, true)
  end

  def create_log(loggable, key, name, endpoint, message, response, error = false, internal = false)
    log = loggable.app_logs.create key: key, endpoint: endpoint, name: name, message: message, response: response, error: error, internal: internal
    log.id
  rescue StandardError => e
    Honeybadger.notify(e)
  end


end