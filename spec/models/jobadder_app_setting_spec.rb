require 'rails_helper'

describe JobadderAppSetting do

  before(:each) do



    @jobadder_app_setting = create(:jobadder_app_setting)
    @ja_setting_attr = attributes_for(:jobadder_app_setting)

  end


  context 'When testing the JobadderAppSetting model' do

    jobadder_field_name_1 = 'address_street'
    registration_question_reference_1 = 'street'

    jobadder_field_name_2 = 'address_postcode'
    registration_question_reference_2 = 'postcode'

    it 'should pass creating settings with all params' do

      ja_setting_fetched = JobadderAppSetting.find_by_dataset_id(@ja_setting_attr[:dataset_id])

      expect(ja_setting_fetched).to have_attributes(:dataset_id => @ja_setting_attr[:dataset_id],
                                                    :ja_client_id => @ja_setting_attr[:ja_client_id],
                                                    :ja_client_secret => @ja_setting_attr[:ja_client_secret],
                                                    :refresh_token => @ja_setting_attr[:refresh_token],
                                                    :access_token => @ja_setting_attr[:access_token],
                                                    :app_url => @ja_setting_attr[:app_url],
                                                    :access_token_expires_at => @ja_setting_attr[:access_token_expires_at])
      expect(ja_setting_fetched.authorised).to be false
      expect(ja_setting_fetched.custom_job_mapping).to be false
      expect(ja_setting_fetched.expire_closed_jobs).to be false
      expect(ja_setting_fetched.auth_settings_filled).to be true

    end


    it 'should pass setting have associated mappings' do

      ja_setting_fetched = JobadderAppSetting.find_by_dataset_id(@ja_setting_attr[:dataset_id])


      JobadderFieldMapping.create({jobadder_app_setting_id: ja_setting_fetched.id,
                                   jobadder_field_name: jobadder_field_name_1,
                                   registration_question_reference: registration_question_reference_1})

      JobadderFieldMapping.create({jobadder_app_setting_id: ja_setting_fetched.id,
                                   jobadder_field_name: jobadder_field_name_2,
                                   registration_question_reference: registration_question_reference_2})


      JobadderFieldMapping.create({jobadder_app_setting_id: 0,
                                   jobadder_field_name: jobadder_field_name_2,
                                   registration_question_reference: registration_question_reference_2})


      ja_settings_with_mappings = JobadderAppSetting.joins(:jobadder_field_mappings).where(jobadder_field_mappings: {jobadder_app_setting_id: ja_setting_fetched.id})

      should accept_nested_attributes_for(:jobadder_field_mappings)

      should have_many(:jobadder_field_mappings).dependent(:destroy)

      expect(ja_settings_with_mappings.length).to eql(2)

    end
    puts 'JobadderAppSetting spec passed!'
  end

end