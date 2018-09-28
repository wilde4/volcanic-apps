require 'rails_helper'

describe JobadderAppSetting do

  dataset_id = 1
  ja_client_id = '123456789'
  ja_client_secret = '987654321'
  refresh_token = 'abc12345'
  access_token = 'def6789'
  app_url = 'www.example.com'
  access_token_expires_at = DateTime.now

  before(:each) do

    JobadderAppSetting.delete_all
    JobadderFieldMapping.delete_all

    ja_setting = JobadderAppSetting.new({dataset_id: dataset_id,
                                         ja_client_id: ja_client_id,
                                         ja_client_secret: ja_client_secret,
                                         refresh_token: refresh_token,
                                         access_token: access_token,
                                         app_url: app_url,
                                         access_token_expires_at: access_token_expires_at})
    ja_setting.save
  end

  after(:each) do
    JobadderAppSetting.delete_all
    JobadderFieldMapping.delete_all
  end

  context 'When testing the JobadderAppSetting model' do

    jobadder_field_name_1 = 'address_street'
    registration_question_reference_1 = 'street'

    jobadder_field_name_2 = 'address_postcode'
    registration_question_reference_2 = 'postcode'

    it 'should pass creating settings with all params' do

      ja_setting_fetched = JobadderAppSetting.find_by_dataset_id(dataset_id)

      expect(ja_setting_fetched).to have_attributes(:dataset_id => dataset_id,
                                                    :ja_client_id => ja_client_id,
                                                    :ja_client_secret => ja_client_secret,
                                                    :refresh_token => refresh_token,
                                                    :access_token => access_token,
                                                    :app_url => app_url,
                                                    :access_token_expires_at => Time.at(access_token_expires_at))
      expect(ja_setting_fetched.authorised).to be false
      expect(ja_setting_fetched.custom_job_mapping).to be false
      expect(ja_setting_fetched.expire_closed_jobs).to be false
      expect(ja_setting_fetched.auth_settings_filled).to be true

      puts 'valid settings'

    end


    it 'should pass setting have associated mappings' do

      ja_setting_fetched = JobadderAppSetting.find_by_dataset_id(dataset_id)


      ja_field_mapping_1 = JobadderFieldMapping.new({jobadder_app_setting_id: ja_setting_fetched.id,
                                                     jobadder_field_name: jobadder_field_name_1,
                                                     registration_question_reference: registration_question_reference_1})
      ja_field_mapping_1.save
      ja_field_mapping_2 = JobadderFieldMapping.new({jobadder_app_setting_id: ja_setting_fetched.id,
                                                     jobadder_field_name: jobadder_field_name_2,
                                                     registration_question_reference: registration_question_reference_2})

      ja_field_mapping_2.save

      ja_field_mapping_3 = JobadderFieldMapping.new({jobadder_app_setting_id: 0,
                                                     jobadder_field_name: jobadder_field_name_2,
                                                     registration_question_reference: registration_question_reference_2})

      ja_field_mapping_3.save


      ja_settings_with_mappings = JobadderAppSetting.joins(:jobadder_field_mappings).where(jobadder_field_mappings: {jobadder_app_setting_id: ja_setting_fetched.id})

      should accept_nested_attributes_for(:jobadder_field_mappings)

      should have_many(:jobadder_field_mappings).dependent(:destroy)

      expect(ja_settings_with_mappings.length).to eql(2)

    end
    puts 'JobadderUser spec passes!'
  end


end