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

      candidate_custom_fields = {'items' => [{'fieldId' => 0, 'name' => 'fav_color', 'type' => 'Text'},
                                             {'fieldId' => 1, 'name' => 'fav_fruit', 'type' => 'Text'},
                                             {'fieldId' => 2, 'name' => 'fav_number', 'type' => 'Number'},
                                             {'fieldId' => 3, 'name' => 'not_fav_number', 'type' => 'Number'}]}

      registration_answers = {'fav_color' => 'black', 'fav_fruit' => 'durian', 'fav_number' => 6}

      custom_fields_answers = @ja_service.send(:construct_custom_fields_answers, candidate_custom_fields, registration_answers)

      expect(custom_fields_answers.nil?).to be false
      expect(custom_fields_answers.is_a? Array).to be true
      expect(custom_fields_answers.length).to eq(3)
      expect(custom_fields_answers.include?({'fieldId' => 0, 'value' => 'black'})).to be true
      expect(custom_fields_answers.include?({'fieldId' => 1, 'value' => 'durian'})).to be true
      expect(custom_fields_answers.include?({'fieldId' => 2, 'value' => 6})).to be true

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

      custom_fields = [{'fieldId' => 0, 'value' => 'black'}, {'fieldId' => 1, 'value' => 'red'}, {'fieldId' => 2, 'value' => 'blue'}]

      json = @ja_service.send(:construct_candidate_request_body, @ja_setting, registration_answers, @user, custom_fields)

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
      expect(json['address']['countryCode']).to eq('answer_address_countryCode')
      expect(json['address']['street'][0]).to eq('answer_address_street')

      expect(json['skillTags'][0]).to eq('answer_skillTags')

      expect(json['employment']['current']['employer']).to eq('answer_employment_current_employer')
      expect(json['employment']['current']['position']).to eq('answer_employment_current_position')
      expect(json['employment']['current']['workTypeId']).to eq(0)
      expect(json['employment']['current']['salary']['ratePer']).to eq('week')
      expect(json['employment']['current']['salary']['rate']).to eq(0)
      expect(json['employment']['current']['salary']['currency']).to eq('answer_employment_current_salary_currency')

      expect(json['employment']['ideal']['position']).to eq('answer_employment_ideal_position')
      expect(json['employment']['ideal']['workTypeId']).to eq(0)
      expect(json['employment']['ideal']['salary']['ratePer']).to eq('week')
      expect(json['employment']['ideal']['salary']['rateHigh']).to eq(0)
      expect(json['employment']['ideal']['salary']['rateLow']).to eq(0)
      expect(json['employment']['ideal']['salary']['currency']).to eq('answer_employment_ideal_salary_currency')

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

      json = @ja_service.send(:construct_candidate_request_body, @ja_setting, registration_answers, @user, nil)
      # recruiterId and statusId accept only integer
      expect(json.length).to eq(16)

      expect(json['seeking']).to be_nil

      expect(json['employment']['current']['workTypeId']).to be_nil
      expect(json['employment']['current']['salary']['rate']).to be_nil

      expect(json['employment']['ideal']['workTypeId']).to be_nil
      expect(json['employment']['ideal']['salary']['rateHigh']).to be_nil
      expect(json['employment']['ideal']['salary']['rateLow']).to be_nil

      expect(json['availability']['immediate']).to be_nil

      # period should be number, unit should be "week/month" => relative hash isn't present
      expect(json['availability']['relative']).to be_nil

      expect(json['recruiterUserId']).to be_nil

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
        else
          registration_answers["ref_#{name}"] = "answer_#{name}"
        end
      end
    end
    return registration_answers
  end

  def get_JSON_string
    return '{
  "firstName": "string",
  "social": {
    "facebook": "https://www.facebook.com/JobAdder"
  },
  "address": {
    "street": [
      "string"
    ],
    "city": "string"
  },
  "skillTags": [
    "string"
  ],
  "employment": {
    "current": {
      "employer": "string",
      "salary": {
        "rate": 0
      }
    },
    "ideal": {
      "position": "string",
      "salary": {
        "currency": "string"
      },
      "other": [
        {
          "workTypeId": 0,
          "salary": {
            "currency": "string"
          }
        }
      ]
    },
    "history": [
      {
        "employer": "string"
      }
    ]
  }
}'
  end

  def create_mappings

    field_mapping_names = get_field_mapping_names
    field_mapping_names.each do |name|

      JobadderFieldMapping.create({jobadder_app_setting_id: @ja_setting.id,
                                   jobadder_field_name: name,
                                   registration_question_reference: "ref_#{name}"})
    end
  end

  def get_json_keys
    return %w{firstName lastName email phone mobile salutation statusId
             rating source seeking social address skillTags employment availability education custom recruiterUserId}
  end

  def get_field_mapping_names
    return %w{address_city address_countryCode address_postalCode address_state address_street
                      availability_date availability_immediate availability_relative_period availability_relative_unit
                      custom_fieldId custom_value education_course education_date education_institution email
                      employment_current_employer employment_current_position employment_current_salary_currency
                      employment_current_salary_rate employment_current_salary_ratePer employment_current_workTypeId employment_history_description
                      employment_history_employer employment_history_end employment_history_position employment_history_start employment_ideal_other_salary_currency
                      employment_ideal_other_salary_rateHigh employment_ideal_other_salary_rateLow employment_ideal_other_salary_ratePer
                      employment_ideal_other_workTypeId employment_ideal_position employment_ideal_salary_currency employment_ideal_salary_rateHigh
                      employment_ideal_salary_rateLow employment_ideal_salary_ratePer employment_ideal_workTypeId firstName lastName mobile phone
                      rating recruiterUserId salutation seeking skillTags social_facebook social_googleplus social_linkedin social_other social_twitter
                      social_youtube source statusId}
  end
end