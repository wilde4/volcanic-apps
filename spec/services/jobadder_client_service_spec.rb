require 'rails_helper'

describe Jobadder::ClientService do

  before(:each) do

    @key = create(:app_key)

    @user = create(:jobadder_user)

    @ja_setting = create(:jobadder_app_setting)

    @ja_service = Jobadder::ClientService.new(@ja_setting)

    create_mappings

  end

  context 'When testing the Jobadder::ClientService' do

    it 'should pass create client service' do

      ja_setting_attr = attributes_for(:jobadder_app_setting)

      urls = JobadderHelper.authentication_urls
      callback_url = JobadderHelper.callback_url

      expect(@ja_service.nil?).to be false
      expect(@ja_service.callback_url).to eq(callback_url)

      expect(@ja_service.authorize_url).to eq("#{urls[:authorize]}?access_type=offline&client_id=#{ja_setting_attr[:ja_client_id]}&redirect_uri=#{callback_url}&response_type=code&scope=read+write+offline_access&state=#{ja_setting_attr[:dataset_id]}")

    end
    it 'should pass return nil client when auth settings not filled' do

      ja_setting = create(:jobadder_app_setting, ja_client_id: '', ja_client_secret: '')

      ja_service = Jobadder::ClientService.new(ja_setting)

      expect(ja_service.nil?).to be false
      expect(ja_service.client).to be_nil

    end

    it 'should refresh access token if expired when setting service up' do

      ja_setting = build(:jobadder_app_setting, access_token_expires_at: 1.hour.ago.to_s, dataset_id: 3)

      stub_request(:post, "https://id.jobadder.com/connect/token").
          with(:body => {"client_id" => "s4voea33fvrepcbzgtil2yt3di", "client_secret" => "n2hna72abr6uxf4y6mpz7od7pqubnu4bkte5oexb34w4ulnrwbtq", "grant_type" => "refresh_token", "refresh_token" => "12499b75ab67dd226ad82ea8e8558b44"},
               :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Faraday v0.9.1'}).
          to_return(:status => 200, :body => {:access_token => 'd2534958b2d3b9e3b0e16c98f91f0184',
                                              :expires_in => 3600,
                                              :token_type => 'Bearer',
                                              :refresh_token => 'e1b495fa69c9bdacbc7e5dd535d4564f',
                                              :api => 'https://api.jobadder.com/v2'}.to_s, :headers => {'Content' => 'application/json'})


      allow(Jobadder::AuthenticationService).to receive_message_chain(:refresh_token, :token).and_return('abc123')

      expiry_date = (DateTime.now + 1).to_i
      allow(Jobadder::AuthenticationService).to receive_message_chain(:refresh_token, :expires_at).and_return((expiry_date))

      expect(ja_setting.access_token).to eq(ja_setting.access_token)
      expect(ja_setting.access_token_expires_at).to eq(ja_setting.access_token_expires_at)

      Jobadder::ClientService.new(ja_setting)

      expect(ja_setting.access_token).to eq('abc123')
      expect(ja_setting.access_token_expires_at).to eq(Time.at(expiry_date))

    end

    it 'should pass  construct custom fields answers' do

      candidate_custom_fields = {'items' => [{'fieldId' => 0, 'name' => 'address_city', 'type' => 'Text'},
                                             {'fieldId' => 1, 'name' => 'address_street', 'type' => 'Text'},
                                             {'fieldId' => 2, 'name' => 'address_postalCode', 'type' => 'Number'},
                                             {'fieldId' => 3, 'name' => 'not_fav_number', 'type' => 'Number'}]}

      registration_answers = {'ref_address_street' => 'Tivot Dale', 'ref_address_city' => 'Stockport', 'ref_address_postalCode' => 53300}

      custom_fields_answers = @ja_service.send(:construct_custom_fields_answers, @ja_setting, candidate_custom_fields, registration_answers)

      expect(custom_fields_answers.nil?).to be false
      expect(custom_fields_answers.is_a? Array).to be true
      expect(custom_fields_answers.length).to eq(3)
      expect(custom_fields_answers.include?({'fieldId' => 0, 'value' => 'Stockport'})).to be true
      expect(custom_fields_answers.include?({'fieldId' => 1, 'value' => 'Tivot Dale'})).to be true
      expect(custom_fields_answers.include?({'fieldId' => 2, 'value' => 53300})).to be true

    end

    it 'should pass  get all keys from deep nested JSON' do

      create(:jobadder_request_body)

      json_body = JSON.parse(JobadderRequestBody.find_by(name: 'add_candidate')[:json])

      extracted_keys = @ja_service.send(:get_all_keys, json_body)


      mappings = get_field_mapping_names

      expect(extracted_keys.nil?).to be false
      expect(extracted_keys.is_a? Array).to be true
      expect(extracted_keys.length).to eq(mappings.size)

      extracted_keys.each do |key|
        expect(mappings).to include(key)
      end


    end

    it 'should pass construct candidate json body with all params' do

      keys = get_json_keys

      registration_answers = construct_registration_answers

      work_types = get_worktypes

      custom_fields = [{'fieldId' => 0, 'value' => 'black'}, {'fieldId' => 1, 'value' => 'red'}, {'fieldId' => 2, 'value' => 'blue'}]

      json = @ja_service.send(:construct_candidate_request_body, @ja_setting, registration_answers, @user, custom_fields, work_types)

      expect(json.length).to eq(18)

      keys.each do |key|
        expect(json.include?(key)).to be true
      end

      expect(json['firstName']).to eq('answer_firstName')
      expect(json['lastName']).to eq('answer_lastName')
      expect(json['email']).to eq('answer_email')
      expect(json['phone']).to eq('answer_phone')
      expect(json['mobile']).to eq('answer_mobile')
      expect(json['salutation']).to eq('answer_salutation')
      expect(json['statusId']).to eq(0)
      expect(json['rating']).to eq('answer_rating')
      expect(json['source']).to eq('answer_source')
      expect(json['seeking']).to eq('yes')

      expect(json['social']['facebook']).to eq('answer_social_facebook')
      expect(json['social']['twitter']).to eq('answer_social_twitter')
      expect(json['social']['linkedin']).to eq('answer_social_linkedin')
      expect(json['social']['googleplus']).to eq('answer_social_googleplus')
      expect(json['social']['youtube']).to eq('answer_social_youtube')
      expect(json['social']['other']).to eq('answer_social_other')

      expect(json['address']['city']).to eq('answer_address_city')
      expect(json['address']['state']).to eq('answer_address_state')
      expect(json['address']['postalCode']).to eq('answer_address_postalCode')
      expect(json['address']['countryCode']).to eq('MY')
      expect(json['address']['street'][0]).to eq('answer_address_street')

      expect(json['skillTags'][0]).to eq('answer_skillTags')

      expect(json['employment']['current']['employer']).to eq('answer_employment_current_employer')
      expect(json['employment']['current']['position']).to eq('answer_employment_current_position')
      expect(json['employment']['current']['workTypeId']).to eq(1154)
      expect(json['employment']['current']['salary']['ratePer']).to eq('week')
      expect(json['employment']['current']['salary']['rate']).to eq(0)
      expect(json['employment']['current']['salary']['currency']).to eq('answer_employment_current_salary_currency')

      expect(json['employment']['ideal']['position']).to eq('answer_employment_ideal_position')
      expect(json['employment']['ideal']['workTypeId']).to eq(1154)
      expect(json['employment']['ideal']['salary']['ratePer']).to eq('week')
      expect(json['employment']['ideal']['salary']['rateHigh']).to eq(0)
      expect(json['employment']['ideal']['salary']['rateLow']).to eq(0)
      expect(json['employment']['ideal']['salary']['currency']).to eq('answer_employment_ideal_salary_currency')

      expect(json['employment']['ideal']['other'][0]['workTypeId']).to eq(1154)
      expect(json['employment']['ideal']['other'][0]['salary']['ratePer']).to eq('week')
      expect(json['employment']['ideal']['other'][0]['salary']['rateHigh']).to eq(0)
      expect(json['employment']['ideal']['other'][0]['salary']['rateLow']).to eq(0)
      expect(json['employment']['ideal']['other'][0]['salary']['currency']).to eq('answer_employment_ideal_other_salary_currency')

      expect(json['employment']['history'][0]['position']).to eq('answer_employment_history_position')
      expect(json['employment']['history'][0]['employer']).to eq('answer_employment_history_employer')
      expect(json['employment']['history'][0]['start']).to eq('answer_employment_history_start')
      expect(json['employment']['history'][0]['end']).to eq('answer_employment_history_end')
      expect(json['employment']['history'][0]['description']).to eq('answer_employment_history_description')

      expect(json['availability']['immediate']).to eq(true)
      expect(json['availability']['relative']['period']).to eq(0)
      expect(json['availability']['relative']['unit']).to eq('week')
      expect(json['availability']['date']).to eq('answer_availability_date')

      expect(json['education'][0]['institution']).to eq('answer_education_institution')
      expect(json['education'][0]['course']).to eq('answer_education_course')
      expect(json['education'][0]['date']).to eq('answer_education_date')

      expect(json['custom'][0]['fieldId']).to eq(0)
      expect(json['custom'][0]['value']).to eq('black')
      expect(json['custom'][1]['fieldId']).to eq(1)
      expect(json['custom'][1]['value']).to eq('red')
      expect(json['custom'][2]['fieldId']).to eq(2)
      expect(json['custom'][2]['value']).to eq('blue')

      expect(json['recruiterUserId'][0]).to eq(0)

    end

    it 'should pass candidate json body validate params' do

      registration_answers = {}
      get_field_mapping_names.each do |name|
        # set all values as String
        registration_answers["ref_#{name}"] = "answer_#{name}"

      end

      json = @ja_service.send(:construct_candidate_request_body, @ja_setting, registration_answers, @user, nil, nil)
      # recruiterId and statusId accept only integer
      expect(json.length).to eq(14)

      expect(json['seeking']).to be_nil

      expect(json['employment']['current']['workType']).to be_nil
      expect(json['employment']['current']['salary']['rate']).to be_nil

      expect(json['employment']['ideal']['workType']).to be_nil
      expect(json['employment']['ideal']['salary']['rateHigh']).to be_nil
      expect(json['employment']['ideal']['salary']['rateLow']).to be_nil

      expect(json['availability']['immediate']).to be_nil

      # period should be number, unit should be "week/month" => relative hash isn't present
      expect(json['availability']['relative']).to be_nil

      expect(json['recruiterUserId']).to be_nil

    end

    it 'should pass candidate json body convert country to countryCode' do

      registration_answers = {}
      registration_answers["ref_address_country"] = "Comoros"


      json = @ja_service.send(:construct_candidate_request_body, @ja_setting, registration_answers, @user, nil, nil)

      expect(json['address']['countryCode']).to eq("KM")

    end

    it 'should pass candidate json body return empty address hash for non-existing country' do

      registration_answers = {}
      registration_answers["ref_address_country"] = "Dorne"

      json = @ja_service.send(:construct_candidate_request_body, @ja_setting, registration_answers, @user, nil, nil)

      expect(json['address']).to be_nil

    end

    it 'should pass get work type id' do

      work_types = get_worktypes

      reg_answer = 'Permanent'

      work_type_id = @ja_service.send(:get_work_type_id, reg_answer, work_types)

      expect(work_type_id).to eq(work_types['items'][0]['workTypeId'])

      reg_answer = 'Contract'

      work_type_id = @ja_service.send(:get_work_type_id, reg_answer, work_types)

      expect(work_type_id).to eq(work_types['items'][1]['workTypeId'])

      reg_answer = 'Permanent or Contract'

      work_type_id = @ja_service.send(:get_work_type_id, reg_answer, work_types)

      expect(work_type_id).to eq(work_types['items'][2]['workTypeId'])

      reg_answer = 'Petata'

      work_type_id = @ja_service.send(:get_work_type_id, reg_answer, work_types)

      expect(work_type_id).to be_nil

    end

    it 'should pass construct current salary hash' do

      question_currency = 'answer_employment_current_salary_currency'
      field_currency = 'MYR'

      question_rate_per = 'answer_employment_current_salary_ratePer'
      field_rate_per = 'hour'

      question_rate = 'answer_employment_current_salary_rate'
      field_rate = 10

      question_rate_low = 'answer_employment_current_salary_rate_low'
      field_rate_low = 5

      question_rate_high = 'answer_employment_current_salary_rate_high'
      field_rate_high = 15

      # true/false flag to indicate current salary
      current_salary_currency = @ja_service.send(:salary, field_currency, question_currency, {}, true)
      current_salary_rate_per = @ja_service.send(:salary, field_rate_per, question_rate_per, {}, true)
      current_salary_rate = @ja_service.send(:salary, field_rate, question_rate, {}, true)
      current_salary_rate_low = @ja_service.send(:salary, field_rate_low, question_rate_low, {}, false)
      current_salary_rate_high = @ja_service.send(:salary, field_rate_high, question_rate_high, {}, false)

      expect(current_salary_currency).to eq({'currency' => 'MYR'})
      expect(current_salary_rate_per).to eq({'ratePer' => 'hour'})
      expect(current_salary_rate).to eq({'rate' => 10})
      expect(current_salary_rate_low).to eq({})
      expect(current_salary_rate_high).to eq({})


    end

    it 'should pass construct ideal/other salary hash' do
      question_currency = 'answer_employment_current_salary_currency'
      field_currency = 'MYR'

      question_rate_per = 'answer_employment_current_salary_ratePer'
      field_rate_per = 'hour'

      question_rate = 'answer_employment_current_salary_rate'
      field_rate = 10

      question_rate_low = 'answer_employment_current_salary_rateLow'
      field_rate_low = 5

      question_rate_high = 'answer_employment_current_salary_rateHigh'
      field_rate_high = 15
      # true/false flag to indicate current salary
      current_salary_currency = @ja_service.send(:salary, field_currency, question_currency, {}, false)
      current_salary_rate_per = @ja_service.send(:salary, field_rate_per, question_rate_per, {}, false)
      current_salary_rate = @ja_service.send(:salary, field_rate, question_rate, {}, false)
      current_salary_rate_low = @ja_service.send(:salary, field_rate_low, question_rate_low, {}, false)
      current_salary_rate_high = @ja_service.send(:salary, field_rate_high, question_rate_high, {}, false)

      expect(current_salary_currency).to eq({'currency' => 'MYR'})
      expect(current_salary_rate_per).to eq({'ratePer' => 'hour'})
      expect(current_salary_rate).to eq({})
      expect(current_salary_rate_low).to eq({'rateLow' => 5})
      expect(current_salary_rate_high).to eq({'rateHigh' => 15})

    end

    it 'should pass validation while constructing salary hash' do

      question_rate_per = 'answer_employment_current_salary_ratePer'
      field_rate_per = 'life'

      question_rate = 'answer_employment_current_salary_rate'
      field_rate = 'Ten'

      question_rate_low = 'answer_employment_current_salary_rate_low'
      field_rate_low = 'Five'

      question_rate_high = 'answer_employment_current_salary_rate_high'
      field_rate_high = 'Twelve'
      # true/false flag to indicate current salary
      current_salary_rate_per = @ja_service.send(:salary, field_rate_per, question_rate_per, {}, true)
      current_salary_rate = @ja_service.send(:salary, field_rate, question_rate, {}, true)
      current_salary_rate_low = @ja_service.send(:salary, field_rate_low, question_rate_low, {}, false)
      current_salary_rate_high = @ja_service.send(:salary, field_rate_high, question_rate_high, {}, false)

      expect(current_salary_rate_per).to eq({})
      expect(current_salary_rate).to eq({})
      expect(current_salary_rate_low).to eq({})
      expect(current_salary_rate_high).to eq({})

    end


    it 'should create and delete file' do

      prefix = 'prefix'

      file_name = 'testFile.pdf'

      test_file = fixture_file_upload('files/Hello.pdf', 'application/pdf')

      file = @ja_service.send(:create_file, prefix, file_name, test_file.path())

      expect(File.exist?(file.path())).to be_truthy
      expect(file.path().to_s.include?("tmp/files/#{prefix}_#{file_name}")).to be_truthy
      expect(file.size()).to be > 0

      @ja_service.send(:delete_file, file)

      expect(File.exist?(file.path())).to be_falsey

    end

    # it 'should construct volcanic fields - ignore upload CV and covering letter registration questions' do
    #
    #   stub_request(:get, "http://test.localhost.volcanic.co/api/v1/user_groups.json").
    #       with(:headers => {'User-Agent' => 'VolcanicJobadderApp'}).
    #       to_return(:status => 200, :body => get_volcanic_registration_questions, :headers => {})
    #
    #   volcanic_fields = @ja_service.send(:get_volcanic_candidate_fields)
    #   expect(volcanic_fields.length).to eq(4)
    #   expect(volcanic_fields['covering-letter']).to be_nil
    #   expect(volcanic_fields['upload-cv']).to be_nil
    #
    # end

    it 'should get volcanic user' do

      stub_request(:get, "#{@key.protocol}#{@key.host}/api/v1/users/#{@user.user_id}.json?api_key=#{@key.api_key}").
          with(:headers => {'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "{hello}", :headers => {})
      volcanic_user = @ja_service.send(:get_volcanic_user, @user.user_id)

      expect(volcanic_user.body).not_to eql(nil)

    end

    puts 'Jobadder::ClientService spec passed!'

  end

  private

  def construct_registration_answers
    registration_answers = {}
    get_field_mapping_names.each do |name|
      unless name === 'custom_fieldId' || name === 'custom_value'
        if name.include?('Id') || name.include?('rateHigh') || name.include?('rateLow') || name === ('employment_current_salary_rate') || name.include?('period')
          registration_answers["ref_#{name}"] = '0'
        elsif name.include?('immediate')
          registration_answers["ref_#{name}"] = true
        elsif (name.include?('relative_unit') || name.include?('ratePer'))
          registration_answers["ref_#{name}"] = 'week'
        elsif name.include?('seeking')
          registration_answers["ref_#{name}"] = 'yes'
        elsif name.include?('workType')
          registration_answers["ref_#{name}"] = 'Permanent'
        elsif name.include?('country')
          registration_answers["ref_#{name}"] = 'Malaysia'
        else
          registration_answers["ref_#{name}"] = "answer_#{name}"
        end
      end
    end
    registration_answers["ref_custom_field_name"] = "custom_field_name_answer"
    return registration_answers
  end

  def get_worktypes
    {"items" => [
        {"workTypeId" => 1154, "name" => "Permanent", "ratePer" => "Year"},
        {"workTypeId" => 1155, "name" => "Contract", "ratePer" => "Hour"},
        {"workTypeId" => 1156, "name" => "Permanent or Contract", "ratePer" => "Hour"},
        {"workTypeId" => 1226, "name" => "Part Time", "ratePer" => "Day"},
        {"workTypeId" => 1227, "name" => "Casual"}
    ]}
  end

  def create_mappings

    field_mapping_names = get_field_mapping_names
    field_mapping_names.each do |name|

      JobadderFieldMapping.create({jobadder_app_setting_id: @ja_setting.id,
                                   jobadder_field_name: name,
                                   registration_question_reference: "ref_#{name}"})
    end

    JobadderFieldMapping.create({jobadder_app_setting_id: @ja_setting.id,
                                 jobadder_field_name: 'Custom field name',
                                 registration_question_reference: "ref_custom_field_name"})

  end

  def get_json_keys
    return %w{firstName lastName email phone mobile salutation statusId
             rating source seeking social address skillTags employment availability education custom recruiterUserId}
  end

  def get_field_mapping_names
    return %w{address_city address_country address_postalCode address_state address_street
                      availability_date availability_immediate availability_relative_period availability_relative_unit
                      education_course education_date education_institution email
                      employment_current_employer employment_current_position employment_current_salary_currency
                      employment_current_salary_rate employment_current_salary_ratePer employment_current_workType employment_history_description
                      employment_history_employer employment_history_end employment_history_position employment_history_start employment_ideal_other_salary_currency
                      employment_ideal_other_salary_rateHigh employment_ideal_other_salary_rateLow employment_ideal_other_salary_ratePer
                      employment_ideal_other_workType employment_ideal_position employment_ideal_salary_currency employment_ideal_salary_rateHigh
                      employment_ideal_salary_rateLow employment_ideal_salary_ratePer employment_ideal_workType firstName lastName mobile phone
                      rating recruiterUserId salutation seeking skillTags social_facebook social_googleplus social_linkedin social_other social_twitter
                      social_youtube source statusId}
  end

  def get_volcanic_registration_questions
    return '[
        {
            "id" : 1,
            "name" : "Candidate",
            "role" : "candidate",
            "allow_registrations" : true,
            "created_at" : "2016-10-14T11:29:36.000+01:00",
            "updated_at" : "2016-10-14T11:29:36.000+01:00",
            "default" : true,
            "users_count" : 3,
            "searchable" : false,
            "cached_slug" : "candidate",
            "registration_question_groups" : [
                {
                    "label" : "Registration",
                    "page_title" : "Registration",
                    "page_body" : "",
                    "submit_text" : "Register",
                    "id" : 1,
                    "created_at" : "2016-10-14T11:29:36.000+01:00",
                    "updated_at" : "2016-10-14T11:29:36.000+01:00",
                    "permalink" : "registration",
                    "next_path" : "/users",
                    "user_type" : "candidate",
                    "user_group_id" : 1,
                    "for_applications" : false,
                    "registration_questions" : [
                        {
                            "label" : "First Name",
                            "id" : 1,
                            "required" : true,
                            "question_type" : "Text",
                            "created_at" : "2016-10-14T11:29:36.000+01:00",
                            "updated_at" : "2016-10-14T11:29:36.000+01:00",
                            "reference" : "first-name",
                            "core_reference" : "first_name",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "extra_settings" : {},
                            "full_hide_on_recruiter_dashboard" : false
                        },
                        {
                            "label" : "Last Name",
                            "id" : 2,
                            "required" : true,
                            "question_type" : "Text",
                            "created_at" : "2016-10-14T11:29:36.000+01:00",
                            "updated_at" : "2016-10-14T11:29:36.000+01:00",
                            "reference" : "last-name",
                            "core_reference" : "last_name",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "extra_settings" : {},
                            "full_hide_on_recruiter_dashboard" : false
                        },
                        {
                            "label" : "Email",
                            "id" : 3,
                            "required" : true,
                            "question_type" : "Text",
                            "created_at" : "2016-10-14T11:29:36.000+01:00",
                            "updated_at" : "2016-10-14T11:29:36.000+01:00",
                            "reference" : "email",
                            "core_reference" : "email",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "extra_settings" : {},
                            "full_hide_on_recruiter_dashboard" : false
                        },
                        {
                            "label" : "Password",
                            "id" : 4,
                            "required" : true,
                            "question_type" : "Text",
                            "created_at" : "2016-10-14T11:29:36.000+01:00",
                            "updated_at" : "2016-10-14T11:29:36.000+01:00",
                            "reference" : "password",
                            "core_reference" : "password",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "extra_settings" : {},
                            "full_hide_on_recruiter_dashboard" : false
                        },
                        {
                            "label" : "Password Confirmation",
                            "id" : 5,
                            "required" : true,
                            "question_type" : "Text",
                            "created_at" : "2016-10-14T11:29:36.000+01:00",
                            "updated_at" : "2016-10-14T11:29:36.000+01:00",
                            "reference" : "password-confirmation",
                            "core_reference" : "password_confirmation",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "extra_settings" : {},
                            "full_hide_on_recruiter_dashboard" : false
                        },
                        {
                            "label" : "Terms and Conditions",
                            "id" : 6,
                            "required" : true,
                            "question_type" : "Checkbox",
                            "created_at" : "2016-10-14T11:29:36.000+01:00",
                            "updated_at" : "2016-10-14T11:29:36.000+01:00",
                            "reference" : "terms-and-conditions",
                            "core_reference" : "terms_and_conditions",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "extra_settings" : {},
                            "full_hide_on_recruiter_dashboard" : false
                        }
                    ]
                },
                {
                    "label" : "Apply for job",
                    "page_title" : "Apply",
                    "page_body" : "",
                    "submit_text" : "Apply Now!",
                    "id" : 72,
                    "created_at" : "2017-07-31T11:18:40.000+01:00",
                    "updated_at" : "2017-07-31T11:18:40.000+01:00",
                    "permalink" : "apply-for-job",
                    "next_path" : "/users",
                    "user_type" : "candidate",
                    "user_group_id" : 1,
                    "for_applications" : true,
                    "registration_questions" : [
                        {
                            "label" : "Upload CV",
                            "id" : 447,
                            "required" : true,
                            "question_type" : "File Upload",
                            "created_at" : "2017-07-31T11:19:12.000+01:00",
                            "updated_at" : "2017-07-31T11:19:12.000+01:00",
                            "reference" : "upload-cv",
                            "core_reference" : "upload_cv",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "extra_settings" : {},
                            "full_hide_on_recruiter_dashboard" : false
                        },
                        {
                            "label" : "Covering Letter",
                            "id" : 448,
                            "required" : true,
                            "question_type" : "File Upload",
                            "created_at" : "2017-07-31T11:19:18.000+01:00",
                            "updated_at" : "2017-07-31T11:19:18.000+01:00",
                            "reference" : "covering-letter",
                            "core_reference" : "covering_letter",
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard" : false,
                            "full_hide_on_recruiter_dashboard" : false
                        },
                        {
                            "label" : "State I reside in",
                            "options" : "a,b,c",
                            "id" : 449,
                            "required" : true,
                            "question_type" : "Drop Down",
                            "created_at" : "2017-07-31T11:21:13.000+01:00",
                            "updated_at" : "2017-07-31T11:21:13.000+01:00",
                            "reference" : "state-i-reside-in",
                            "job_search" : false,
                            "geocodable" : false,
                            "filter_exclude" : false,
                            "column_width" : 12,
                            "hide_label" : false,
                            "show_on_dashboard"  : false,
                            "full_hide_on_recruiter_dashboard"  : false
                        }
                    ]
                }
            ]
        },
        {
            "id" : 2,
            "name" : "Admin",
            "role" : "admin",
            "allow_registrations" : false,
            "created_at" : "2016-10-14T11:29:36.000+01:00",
            "updated_at" : "2016-10-14T11:29:36.000+01:00",
            "default" : false,
            "users_count" : 13,
            "searchable" : false,
            "cached_slug" : "admin",
            "registration_question_groups" : []
        }
    ]'
  end

  def get_volcanic_user
    return '{
"delta": {
"id": 106,
"email": "roro@ror.com",
"created_at": "2018-11-09T10:48:00.000+00:00",
"updated_at": "2018-11-09T10:48:15.000+00:00",
"role": "candidate",
"terms_and_conditions": false,
"user_type": null,
"deleted_at": null,
"user_group": "Candidate",
"first_name": "Roro",
"last_name": "Moro",
"featured": null,
"re_register_email_sent_at": null,
"user_group_id": 1,
"source": null,
"client_id": null,
"suspended": false,
"full_registration": true,
"invitation_token": null,
"invitation_created_at": null,
"invitation_sent_at": null,
"invitation_accepted_at": null,
"invitation_limit": null,
"invited_by_id": null,
"invited_by_type": null,
"locale": null,
"remote_id": null,
"avatar_thumb_path": null,
"avatar_medium_cropped_path": null,
"avatar_medium_uncropped_path": null,
"avatar_large_cropped_path": null,
"avatar_large_uncropped_path": null,
"job_alert_frequency": "Weekly",
"google_cid": null,
"registration_answers": [
{
"file-upload-1": "/s3/W1siZiIsIjIwMTgvMTEvMDkvMTAvNDgvMDAvMTEyLzEyNzdfQ1Zfc2FtcGxlLnBkZiJdXQ"
}
],
"user_cvs": [
{
"id": 180,
"name": "CV_sample.pdf",
"url": "https://oliver-development.s3.amazonaws.com/candidate-uploads/documents/1/38f3c86a-6e6e-4476-8d78-18e3e5656125/CV_sample.pdf?X-Amz-Expires=3600&X-Amz-Date=20181109T110936Z&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIXPGQUY26ZFKX4GA/20181109/us-east-1/s3/aws4_request&X-Amz-SignedHeaders=host&X-Amz-Signature=20939436d35949ee77f60bc6bb6b1ff71bbeeaa3f980733e8efcd24c990e366d"
}
],
"user_covering_letters": [
{
"id": 181,
"name": "Cover_Letter_sample_copy.pdf",
"url": "https://oliver-development.s3.amazonaws.com/candidate-uploads/documents/1/c68b5c33-97d4-4ff1-9df5-0f57cdd97358/Cover_Letter_sample_copy.pdf?X-Amz-Expires=3600&X-Amz-Date=20181109T110936Z&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIXPGQUY26ZFKX4GA/20181109/us-east-1/s3/aws4_request&X-Amz-SignedHeaders=host&X-Amz-Signature=72aabf78b08009b8844ddb896924c15594a38321c314eb255efa7cbcfa9863b5"
}
],
"job_alerts": [],
"job_applications": [
{
"application_id": 68,
"application_date": "2018-11-09T10:48:09.000+00:00",
"job_id": 6,
"job_title": "IT Director",
"job_reference": "1277",
"job_location": "Sydney",
"job_featured": false,
"job_url": "amazing-job-6",
"cv_id": 180,
"covering_letter_id": 181
}
],
"rumble_events": [
{
"id": 491,
"visitor_uid": "2qyb1kfql7i",
"url": "development.localhost.volcanic.co/job/amazing-job-6/apply",
"keywords": null,
"utm_source": null,
"utm_medium": null,
"utm_campaign": null,
"source_record_id": null,
"source_record_type": null
}
],
"legal_documents": [
{
"key": "privacy_policy",
"title": "Privacy",
"version": 1,
"consented": true,
"consent_type": "explicit",
"consented_at": "2018-11-09T10:48:09.000+00:00"
}
],
"legal_documents_history": [
{
"key": "privacy_policy",
"title": "Privacy",
"version": 1,
"event": "consent_given",
"occurred_at": "2018-11-09T10:48:09.000+00:00"
}
]
},
"id": 106,
"email": "roro@ror.com",
"created_at": "2018-11-09T10:48:00.000+00:00",
"updated_at": "2018-11-09T10:48:15.000+00:00",
"role": "candidate",
"terms_and_conditions": false,
"user_type": null,
"deleted_at": null,
"user_group": "Candidate",
"first_name": "Roro",
"last_name": "Moro",
"featured": null,
"re_register_email_sent_at": null,
"user_group_id": 1,
"source": null,
"client_id": null,
"suspended": false,
"full_registration": true,
"invitation_token": null,
"invitation_created_at": null,
"invitation_sent_at": null,
"invitation_accepted_at": null,
"invitation_limit": null,
"invited_by_id": null,
"invited_by_type": null,
"locale": null,
"remote_id": null,
"avatar_thumb_path": null,
"avatar_medium_cropped_path": null,
"avatar_medium_uncropped_path": null,
"avatar_large_cropped_path": null,
"avatar_large_uncropped_path": null,
"job_alert_frequency": "Weekly",
"google_cid": null,
"registration_answers": [
{
"file-upload-1": "/s3/W1siZiIsIjIwMTgvMTEvMDkvMTAvNDgvMDAvMTEyLzEyNzdfQ1Zfc2FtcGxlLnBkZiJdXQ"
}
],
"user_cvs": [
{
"id": 180,
"name": "CV_sample.pdf",
"url": "https://oliver-development.s3.amazonaws.com/candidate-uploads/documents/1/38f3c86a-6e6e-4476-8d78-18e3e5656125/CV_sample.pdf?X-Amz-Expires=3600&X-Amz-Date=20181109T110935Z&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIXPGQUY26ZFKX4GA/20181109/us-east-1/s3/aws4_request&X-Amz-SignedHeaders=host&X-Amz-Signature=b28fccbc206d51648205036fa1d53dac131237423cfe0f575dee1f0582c3f359"
}
],
"user_covering_letters": [
{
"id": 181,
"name": "Cover_Letter_sample_copy.pdf",
"url": "https://oliver-development.s3.amazonaws.com/candidate-uploads/documents/1/c68b5c33-97d4-4ff1-9df5-0f57cdd97358/Cover_Letter_sample_copy.pdf?X-Amz-Expires=3600&X-Amz-Date=20181109T110935Z&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIXPGQUY26ZFKX4GA/20181109/us-east-1/s3/aws4_request&X-Amz-SignedHeaders=host&X-Amz-Signature=01a5a6f30cd77a99175812ec398729716599555b0f3ef1450b3a62450b25db33"
}
],
"job_alerts": [],
"job_applications": [
{
"application_id": 68,
"application_date": "2018-11-09T10:48:09.000+00:00",
"job_id": 6,
"job_title": "IT Director",
"job_reference": "1277",
"job_location": "Sydney",
"job_featured": false,
"job_url": "amazing-job-6",
"cv_id": 180,
"covering_letter_id": 181
}
],
"rumble_events": [
{
"id": 491,
"visitor_uid": "2qyb1kfql7i",
"url": "development.localhost.volcanic.co/job/amazing-job-6/apply",
"keywords": null,
"utm_source": null,
"utm_medium": null,
"utm_campaign": null,
"source_record_id": null,
"source_record_type": null
}
],
"legal_documents": [
{
"key": "privacy_policy",
"title": "Privacy",
"version": 1,
"consented": true,
"consent_type": "explicit",
"consented_at": "2018-11-09T10:48:09.000+00:00"
}
],
"legal_documents_history": [
{
"key": "privacy_policy",
"title": "Privacy",
"version": 1,
"event": "consent_given",
"occurred_at": "2018-11-09T10:48:09.000+00:00"
}
]
}'
  end
end