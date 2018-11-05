require 'rails_helper'

describe JobadderController, :type => :controller do

  before(:each) do
    @key = create(:app_key)
  end

  after(:each) do
    JobadderAppSetting.delete_all
    Key.delete_all
  end

  context 'When testing the JobadderController' do

    it 'should pass GET #index without jobadder auth settings filled' do

      data = {:action => 'app_html',
              :controller => 'admin/apps',
              :id => 38, :dataset_id => 2,
              :original_url => 'http://development.localhost.volcanic.co:3000/admin/apps/38/app_html'}


      get :index, :data => data

      expect(response.status).to eq(200)
      expect(assigns(:ja_setting)).not_to be_nil
      expect(assigns(:ja_service)).not_to be_nil
      expect(assigns(:volcanic_candidate_fields)).to be_nil
      expect(assigns(:ja_candidate_fields)).to be_nil

    end

    it 'should pass GET #index with jobadder auth settings filled' do

      jobadder_setting = create(:jobadder_app_setting)

      data = {:action => 'app_html',
              :controller => 'admin/apps',
              :id => 38, :dataset_id => 2,
              :original_url => 'http://development.localhost.volcanic.co:3000/admin/apps/38/app_html'}


      create_json
      create(:jobadder_app_setting)
      stub_get_fields

      get :index, :data => data

      expect(response.status).to eq(200)
      expect(assigns(:ja_setting)).not_to be_nil
      expect(assigns(:ja_service)).not_to be_nil

      expect(assigns(:volcanic_candidate_fields)).not_to be_nil
      expect(assigns(:ja_candidate_fields)).not_to be_nil

      expect(assigns(:volcanic_candidate_fields).size).to eq(3)
      expect(assigns(:ja_setting).jobadder_field_mappings.size).to eq(3)

      assigns(:ja_setting).jobadder_field_mappings.each do |item|

        item.registration_question_reference

        expect(item.registration_question_reference === 'email' ||
                   item.registration_question_reference === 'last-name' ||
                   item.registration_question_reference === 'first-name').to be_truthy

      end

    end

    it 'should pass POST #update client_id only ' do

      ja_setting_init = create(:jobadder_app_setting)

      ja_setting_upd = {:ja_client_id => 'abcdef123456',
                        :ja_client_secret => ja_setting_init.ja_client_secret,
                        :dataset_id => ja_setting_init.dataset_id}


      create_json
      stub_get_fields


      post :update, :jobadder_app_setting => ja_setting_upd

      expect(response.status).to eq(200)

      expect(assigns(:ja_setting).authorised).to be_falsey

      expect(assigns(:ja_setting).ja_client_id).to eq(ja_setting_upd[:ja_client_id])

      expect(assigns(:ja_setting).ja_client_secret).to eq(ja_setting_upd[:ja_client_secret])

      ja_settig_fetched = JobadderAppSetting.find_by(dataset_id: ja_setting_upd[:dataset_id])

      expect(ja_settig_fetched.ja_client_id).to eq(ja_setting_upd[:ja_client_id])

      expect(ja_settig_fetched.ja_client_secret).to eq(ja_setting_upd[:ja_client_secret])

      expect(flash[:notice]).to eq "Settings successfully saved."

      expect(response.body).to eq ("window.open('#{assigns(:ja_service).authorize_url}', '_self')")

      expect(assigns(:ja_setting).jobadder_field_mappings.size).to eq(3)

      assigns(:ja_setting).jobadder_field_mappings.each do |item|

        item.registration_question_reference

        expect(item.registration_question_reference === 'email' ||
                   item.registration_question_reference === 'last-name' ||
                   item.registration_question_reference === 'first-name').to be_truthy

      end

    end


    it 'should pass POST #update client_secret only ' do

      ja_setting_init = create(:jobadder_app_setting)

      ja_setting_upd = {:ja_client_id => ja_setting_init.ja_client_id,
                        :ja_client_secret => '123456abcdef',
                        :dataset_id => ja_setting_init.dataset_id}

      create_json
      stub_get_fields

      post :update, :jobadder_app_setting => ja_setting_upd

      expect(response.status).to eq(200)

      expect(assigns(:ja_setting).authorised).to be_falsey

      expect(assigns(:ja_setting).ja_client_id).to eq(ja_setting_init.ja_client_id)

      expect(assigns(:ja_setting).ja_client_secret).to eq(ja_setting_upd[:ja_client_secret])

      ja_settig_fetched = JobadderAppSetting.find_by(dataset_id: ja_setting_upd[:dataset_id])

      expect(ja_settig_fetched.ja_client_id).to eq(ja_setting_upd[:ja_client_id])

      expect(ja_settig_fetched.ja_client_secret).to eq(ja_setting_upd[:ja_client_secret])

      expect(flash[:notice]).to eq "Settings successfully saved."

      expect(response.body).to eq ("window.open('#{assigns(:ja_service).authorize_url}', '_self')")

      expect(assigns(:ja_setting).jobadder_field_mappings.size).to eq(3)

      assigns(:ja_setting).jobadder_field_mappings.each do |item|

        item.registration_question_reference

        expect(item.registration_question_reference === 'email' ||
                   item.registration_question_reference === 'last-name' ||
                   item.registration_question_reference === 'first-name').to be_truthy

      end

    end

    it 'should pass POST #update client_secret & client_id ' do

      ja_setting_init = create(:jobadder_app_setting)

      ja_setting_upd = {:ja_client_id => 'abcdef123456',
                        :ja_client_secret => '123456abcdef',
                        :dataset_id => ja_setting_init.dataset_id}

      create_json
      stub_get_fields

      post :update, :jobadder_app_setting => ja_setting_upd

      expect(response.status).to eq(200)

      expect(assigns(:ja_setting).authorised).to be_falsey

      expect(assigns(:ja_setting).ja_client_id).to eq(ja_setting_upd[:ja_client_id])

      expect(assigns(:ja_setting).ja_client_secret).to eq(ja_setting_upd[:ja_client_secret])

      ja_settig_fetched = JobadderAppSetting.find_by(dataset_id: ja_setting_upd[:dataset_id])

      expect(ja_settig_fetched.ja_client_id).to eq(ja_setting_upd[:ja_client_id])

      expect(ja_settig_fetched.ja_client_secret).to eq(ja_setting_upd[:ja_client_secret])

      expect(flash[:notice]).to eq "Settings successfully saved."

      expect(response.body).to eq ("window.open('#{assigns(:ja_service).authorize_url}', '_self')")

      expect(assigns(:ja_setting).jobadder_field_mappings.size).to eq(3)

      assigns(:ja_setting).jobadder_field_mappings.each do |item|

        item.registration_question_reference

        expect(item.registration_question_reference === 'email' ||
                   item.registration_question_reference === 'last-name' ||
                   item.registration_question_reference === 'first-name').to be_truthy

      end

    end


    it 'should pass POST #update field mappings only' do


      ja_setting_upd = create(:jobadder_app_setting)

      id = ja_setting_upd.id


      mapping_1 = create(:jobadder_field_mapping,
                         jobadder_app_setting_id: ja_setting_upd.id,
                         jobadder_field_name: '',
                         registration_question_reference: 'first-name'
      )

      mapping_2 = create(:jobadder_field_mapping,
                         jobadder_app_setting_id: ja_setting_upd.id,
                         jobadder_field_name: '',
                         registration_question_reference: 'last-name'
      )

      mapping_3 = create(:jobadder_field_mapping,
                         jobadder_app_setting_id: ja_setting_upd.id
      )


      ja_setting_upd = {
          :dataset_id => ja_setting_upd.dataset_id,
          :jobadder_field_mappings_attributes => {'0' => {:id => mapping_3.id,
                                                          :jobadder_field_name => 'email',
                                                          :registration_question_reference => 'email',
                                                          :jobadder_app_setting_id => id},
                                                  '1' => {:id => mapping_2.id,
                                                          :jobadder_field_name => 'firstName',
                                                          :registration_question_reference => 'first-name',
                                                          :jobadder_app_setting_id => id},
                                                  '2' => {:id => mapping_1.id,
                                                          :jobadder_field_name => 'lastName',
                                                          :registration_question_reference => 'last-name',
                                                          :jobadder_app_setting_id => id}
          }
      }

      create_json
      stub_get_fields

      post :update, :jobadder_app_setting => ja_setting_upd

      expect(response.status).to eq(200)

      expect(flash[:notice]).to eq "Settings successfully saved."

      mappings = JobadderFieldMapping.where("jobadder_app_setting_id =#{id}").to_a

      expect(mappings.size).to eq(3)

      mappings.each do |item|

        expect(item.jobadder_field_name === 'email' ||
                   item.jobadder_field_name === 'lastName' ||
                   item.jobadder_field_name === 'firstName').to be_truthy

      end

    end


    it 'should pass POST #update destroy mappings' do


      ja_setting_upd = create(:jobadder_app_setting)

      id = ja_setting_upd.id


      mapping_1 = create(:jobadder_field_mapping,
                         jobadder_app_setting_id: ja_setting_upd.id,
                         jobadder_field_name: 'firstName',
                         registration_question_reference: 'first-name'
      )

      mapping_2 = create(:jobadder_field_mapping,
                         jobadder_app_setting_id: ja_setting_upd.id,
                         jobadder_field_name: 'lastName',
                         registration_question_reference: 'last-name'
      )

      mapping_3 = create(:jobadder_field_mapping,
                         jobadder_app_setting_id: ja_setting_upd.id
      )


      ja_setting_upd = {
          :dataset_id => ja_setting_upd.dataset_id,
          :jobadder_field_mappings_attributes => {'0' => {:id => mapping_3.id,
                                                          :jobadder_field_name => '',
                                                          :registration_question_reference => 'email',
                                                          :jobadder_app_setting_id => id},
                                                  '1' => {:id => mapping_2.id,
                                                          :jobadder_field_name => '',
                                                          :registration_question_reference => 'first-name',
                                                          :jobadder_app_setting_id => id},
                                                  '2' => {:id => mapping_1.id,
                                                          :jobadder_field_name => '',
                                                          :registration_question_reference => 'last-name',
                                                          :jobadder_app_setting_id => id}
          }
      }

      create_json
      stub_get_fields

      post :update, :jobadder_app_setting => ja_setting_upd

      expect(response.status).to eq(200)

      expect(flash[:notice]).to eq "Settings successfully saved."

      mappings = JobadderFieldMapping.where("jobadder_app_setting_id =#{id}").to_a

      expect(mappings.size).to eq(0)


    end

    it 'should pass POST #callback authorise and save setting' do

      ja_setting = create(:jobadder_app_setting, access_token: '', refresh_token: '', access_token_expires_at: '')

      code = 12345
      state = ja_setting.dataset_id
      access_token = 'd2534958b2d3b9e3b0e16c98f91f0184'
      refresh_token = 'e1b495fa69c9bdacbc7e5dd535d4564f'
      expiry_date = (DateTime.now + 1).to_i

      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :token).and_return(access_token)
      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :refresh_token).and_return(refresh_token)
      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :expires_at).and_return((expiry_date))

      post :callback, :code => code, :state => state

      ja_settig_fetched = JobadderAppSetting.find_by(dataset_id: ja_setting.dataset_id)

      expect(ja_settig_fetched.access_token).to eq(access_token)

      expect(ja_settig_fetched.refresh_token).to eq(refresh_token)

      expect(ja_settig_fetched.access_token_expires_at).to eq(Time.at(expiry_date))

      expect(flash[:notice]).to eq "App successfully authorised."

      expect(response).to redirect_to(ja_setting.app_url)

    end

    it 'should pass POST #save_candidate create new user' do

      ja_setting = create(:jobadder_app_setting)


      user = {'id' => 5,
              'dataset_id' => ja_setting.dataset_id,
              'email' => 'myemail@email.com',
              'user_profile' => {'first_name' => 'Johny', 'last_name' => 'Deep'}
      }

      expiry_date = (DateTime.now + 1).to_i

      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :token).and_return(ja_setting.access_token)
      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :refresh_token).and_return(ja_setting.refresh_token)
      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :expires_at).and_return((expiry_date))

      stub_request(:get, "https://api.jobadder.com/v2/candidates?email=johny@email.com").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "{\"items\":[]}", :headers => {'Content-Type' => 'application/json'})

      stub_request(:get, "https://api.jobadder.com/v2/candidates/fields/custom").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "{}", :headers => {})

      stub_request(:post, "https://api.jobadder.com/v2/candidates").
          with(:body => "{\"firstName\":\"#{user['user_profile']['first_name']}\",\"lastName\":\"#{user['user_profile']['last_name']}\",\"email\":\"#{user['email']}\"}",
               :headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "{\"candidateId\" : 12345}", :headers => {'Content-Type' => 'application/json'})

      stub_request(:get, "https://api.jobadder.com/v2/candidates?email=#{user['email']}").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "{\"items\":[]}", :headers => {'Content-Type' => 'application/json'})

      stub_request(:get, "https://api.jobadder.com/v2/worktypes").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "", :headers => {})


      user_fetched_before = JobadderUser.find_by(user_id: user['id'])

      expect(user_fetched_before).to be_nil

      post :save_candidate, :user => user, :user_profile => user['user_profile']

      expect(response.status).to eq(200)

      user_fetched_after = JobadderUser.find_by(user_id: user['id'])

      expect(user_fetched_after).to have_attributes(:user_id => user['id'],
                                                    :email => user['email'],
                                                    :user_profile => user['user_profile'])

    end

    it 'should pass POST #save_candidate update  existing user' do

      ja_setting = create(:jobadder_app_setting)

      user = create(:jobadder_user)


      user_updated = {'id' => user['user_id'],
                      'dataset_id' => ja_setting.dataset_id,
                      'email' => 'updated@email.com',
                      'user_profile' => {'first_name' => 'Johny', 'last_name' => 'Shallow'}
      }


      expiry_date = (DateTime.now + 1).to_i

      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :token).and_return(ja_setting.access_token)
      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :refresh_token).and_return(ja_setting.refresh_token)
      allow(Jobadder::AuthenticationService).to receive_message_chain(:get_access_token, :expires_at).and_return((expiry_date))

      stub_request(:get, "https://api.jobadder.com/v2/candidates?email=#{user_updated['email']}").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "{\"items\":[]}", :headers => {'Content-Type' => 'application/json'})

      stub_request(:get, "https://api.jobadder.com/v2/candidates/fields/custom").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "{}", :headers => {})

      stub_request(:post, "https://api.jobadder.com/v2/candidates").
          with(:body => "{\"firstName\":\"#{user_updated['user_profile']['first_name']}\",\"lastName\":\"#{user_updated['user_profile']['last_name']}\",\"email\":\"#{user_updated['email']}\"}",
               :headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "{\"candidateId\" : 12345}", :headers => {'Content-Type' => 'application/json'})

      stub_request(:get, "https://api.jobadder.com/v2/candidates?email=#{user_updated['email']}").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "{\"items\":[]}", :headers => {'Content-Type' => 'application/json'})

      stub_request(:get, "https://api.jobadder.com/v2/worktypes").
          with(:headers => {'Authorization' => "Bearer #{ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "", :headers => {})


      user_fetched_before = JobadderUser.find_by(user_id: user['user_id'])

      expect(user_fetched_before).not_to be_nil

      post :save_candidate, :user => user_updated, :user_profile => user_updated['user_profile']

      expect(response.status).to eq(200)

      user_fetched_after = JobadderUser.find_by(user_id: user['user_id'])

      expect(user_fetched_after).to have_attributes(:user_id => user_updated['id'],
                                                    :email => user_updated['email'],
                                                    :user_profile => user_updated['user_profile'])

    end

    it 'should pass construct jobadder field mappings' do

      create_json

      controller = JobadderController.new


      ja_setting = create(:jobadder_app_setting)

      ja_service = Jobadder::ClientService.new(ja_setting)

      stub_get_fields

      controller.instance_variable_set('@ja_setting', ja_setting)
      controller.instance_variable_set('@ja_service', ja_service)

      controller.send(:get_fields)

      expect(ja_setting.jobadder_field_mappings.size).to eq(3)

      ja_setting.jobadder_field_mappings.each do |item|

        item.registration_question_reference

        expect(item.registration_question_reference === 'email' ||
                   item.registration_question_reference === 'last-name' ||
                   item.registration_question_reference === 'first-name').to be_truthy

      end

    end

    puts 'JobadderController spec passed!'

  end

  private

  def stub_get_fields
    volcanic_fields = get_volcanic_fields

    stub_request(:get, "http://test.localhost.volcanic.co/api/v1/user_groups.json").
        with(:headers => {'User-Agent' => 'VolcanicJobadderApp'}).
        to_return(:status => 200, :body => volcanic_fields, :headers => {'Content-Type' => 'application/json'})

    stub_request(:get, "https://api.jobadder.com/v2/candidates/fields/custom").
        with(:headers => {'Authorization' => 'Bearer 669ffc69f8a360c61c06c7f87672a280', 'User-Agent' => 'VolcanicJobadderApp'}).
        to_return(:status => 200, :body => "", :headers => {})
  end

  def create_json
    json = '{
"firstName": "string",
"lastName": "string",
"email": "string",
"phone": "string",
"mobile": "string",
"salutation": "string",
"statusId": 0,
"rating": "string",
"source": "string",
"seeking": "Yes",
"social": {
"property1": "string",
"property2": "string"
},
"address": {
"street": [
"string"
],
"city": "string",
"state": "string",
"postalCode": "string",
"countryCode": "string"
},
"skillTags": [
"string"
],
"employment": {
"current": {
"employer": "string",
"position": "string",
"workTypeId": 0,
"salary": {
"ratePer": "Hour",
"rate": 0,
"currency": "string"
}
},
"ideal": {
"position": "string",
"workTypeId": 0,
"salary": {
"ratePer": "Hour",
"rateLow": 0,
"rateHigh": 0,
"currency": "string"
},
"other": [
{
"workTypeId": 0,
"salary": {
"ratePer": "Hour",
"rateLow": 0,
"rateHigh": 0,
"currency": "string"
}
}
]
},
"history": [
{
"employer": "string",
"position": "string",
"start": "string",
"end": "string",
"description": "string"
}
]
},
"availability": {
"immediate": true,
"relative": {
"period": 0,
"unit": "Week"
},
"date": "2018-08-24"
},
"education": [
{
"institution": "string",
"course": "string",
"date": "string"
}
],
"custom": [
{
"fieldId": 0,
"value": { }
}
],
"recruiterUserId": [
0
]
}
'
    JobadderRequestBody.create(request_type: 'POST', endpoint: '/candidates', name: 'add_candidate', json: json)
  end

  def get_volcanic_fields
    return '[{
            "id": 1,
            "name": "Candidate",
            "role": "candidate",
            "allow_registrations": true,
            "created_at": "2018-03-19T16:39:03.000+00:00",
            "updated_at": "2018-03-19T16:39:03.000+00:00",
            "default": true,
            "after_sign_in_path": null,
            "users_count": 9,
            "searchable": false,
            "cached_slug": "candidate",
            "admin_default": false,
            "registration_question_groups": [
                {
                "label": "Registration",
            "page_title": "Registration",
            "page_body": "",
            "submit_text": "Register",
            "submit_edit_text": null,
            "id": 1,
            "created_at": "2018-03-19T16:39:03.000+00:00",
            "updated_at": "2018-03-19T16:39:04.000+00:00",
            "permalink": "registration",
            "next_group_id": null,
            "next_path": "/users",
            "user_type": "candidate",
            "deleted_at": null,
            "user_group_id": 1,
            "for_applications": false,
            "registration_questions": [
                {
                "label": "First Name",
            "hint": null,
            "placeholder": null,
            "options": null,
            "id": 1,
            "required": null,
            "question_type": "Text",
            "created_at": "2018-03-19T16:39:04.000+00:00",
            "updated_at": "2018-10-09T12:33:46.000+01:00",
            "position": null,
            "parent_id": null,
            "reference": "first-name",
            "core_reference": "first_name",
            "deleted_at": null,
            "job_search": null,
            "geocodable": false,
            "filter_exclude": false,
            "column_width": 12,
            "hide_label": false,
            "show_on_dashboard": false,
            "min_input": null,
            "max_input": null,
            "source": null,
            "hide_on_recruiter_dashboard": null,
            "extra_settings": {},
        "full_hide_on_recruiter_dashboard": false
    },
        {
            "label": "Last Name",
            "hint": null,
            "placeholder": null,
            "options": null,
            "id": 2,
            "required": null,
            "question_type": "Text",
            "created_at": "2018-03-19T16:39:04.000+00:00",
            "updated_at": "2018-10-09T12:33:46.000+01:00",
            "position": null,
            "parent_id": null,
            "reference": "last-name",
            "core_reference": "last_name",
            "deleted_at": null,
            "job_search": null,
            "geocodable": false,
            "filter_exclude": false,
            "column_width": 12,
            "hide_label": false,
            "show_on_dashboard": false,
            "min_input": null,
            "max_input": null,
            "source": null,
            "hide_on_recruiter_dashboard": null,
            "extra_settings": {},
        "full_hide_on_recruiter_dashboard": false
    },
        {
            "label": "Email",
            "hint": null,
            "placeholder": null,
            "options": null,
            "id": 3,
            "required": null,
            "question_type": "Text",
            "created_at": "2018-03-19T16:39:04.000+00:00",
            "updated_at": "2018-10-09T12:33:46.000+01:00",
            "position": null,
            "parent_id": null,
            "reference": "email",
            "core_reference": "email",
            "deleted_at": null,
            "job_search": null,
            "geocodable": false,
            "filter_exclude": false,
            "column_width": 12,
            "hide_label": false,
            "show_on_dashboard": false,
            "min_input": null,
            "max_input": null,
            "source": null,
            "hide_on_recruiter_dashboard": null,
            "extra_settings": {},
        "full_hide_on_recruiter_dashboard": false
    },
        {
            "label": "Terms and Conditions",
            "hint": null,
            "placeholder": null,
            "options": null,
            "id": 6,
            "required": true,
            "question_type": "Checkbox",
            "created_at": "2018-03-19T16:39:04.000+00:00",
            "updated_at": "2018-03-19T16:39:04.000+00:00",
            "position": null,
            "parent_id": null,
            "reference": "terms-and-conditions",
            "core_reference": "terms_and_conditions",
            "deleted_at": null,
            "job_search": null,
            "geocodable": false,
            "filter_exclude": false,
            "column_width": 12,
            "hide_label": false,
            "show_on_dashboard": false,
            "min_input": null,
            "max_input": null,
            "source": null,
            "hide_on_recruiter_dashboard": null,
            "extra_settings": {},
        "full_hide_on_recruiter_dashboard": false
    },
        {
            "label": "Password",
            "hint": null,
            "placeholder": null,
            "options": null,
            "id": 8,
            "required": true,
            "question_type": "Text",
            "created_at": "2018-10-09T13:31:19.000+01:00",
            "updated_at": "2018-10-09T13:31:19.000+01:00",
            "position": null,
            "parent_id": null,
            "reference": "password-1",
            "core_reference": "password",
            "deleted_at": null,
            "job_search": null,
            "geocodable": false,
            "filter_exclude": false,
            "column_width": 12,
            "hide_label": false,
            "show_on_dashboard": false,
            "min_input": null,
            "max_input": null,
            "source": null,
            "hide_on_recruiter_dashboard": null,
            "extra_settings": {},
        "full_hide_on_recruiter_dashboard": false
    },
        {
            "label": "Password Confirmation",
            "hint": null,
            "placeholder": null,
            "options": null,
            "id": 9,
            "required": true,
            "question_type": "Text",
            "created_at": "2018-10-09T13:31:40.000+01:00",
            "updated_at": "2018-10-09T13:31:41.000+01:00",
            "position": null,
            "parent_id": null,
            "reference": "password-confirmation-1",
            "core_reference": "password_confirmation",
            "deleted_at": null,
            "job_search": null,
            "geocodable": false,
            "filter_exclude": false,
            "column_width": 12,
            "hide_label": false,
            "show_on_dashboard": false,
            "min_input": null,
            "max_input": null,
            "source": null,
            "hide_on_recruiter_dashboard": null,
            "extra_settings": {},
        "full_hide_on_recruiter_dashboard": false
    }
    ]
    }
    ]
    },
        {
            "id": 2,
            "name": "Admin",
            "role": "admin",
            "allow_registrations": false,
            "created_at": "2018-03-19T16:39:04.000+00:00",
            "updated_at": "2018-03-19T16:39:04.000+00:00",
            "default": false,
            "after_sign_in_path": null,
            "users_count": 2,
            "searchable": false,
            "cached_slug": "admin",
            "admin_default": false,
            "registration_question_groups": []
        }
    ]'
  end

end