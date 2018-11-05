require 'rails_helper'

describe JobadderFieldMapping do


  context 'When testing the JobadderFieldMapping model' do

    jobadder_app_setting_id = 1
    jobadder_field_name = 'employment_current'
    registration_question_reference = 'employment'
    job_attribute = 'attribute'

    it 'should pass creating field mapping with all params' do

      JobadderFieldMapping.create({jobadder_app_setting_id: jobadder_app_setting_id,
                                   jobadder_field_name: jobadder_field_name,
                                   registration_question_reference: registration_question_reference,
                                   job_attribute: job_attribute})


      field_mapping_fetched = JobadderFieldMapping.find_by_jobadder_app_setting_id(jobadder_app_setting_id)

      expect(field_mapping_fetched).to have_attributes(:jobadder_app_setting_id => jobadder_app_setting_id,
                                                       :jobadder_field_name => jobadder_field_name,
                                                       :registration_question_reference => registration_question_reference,
                                                       :job_attribute => job_attribute)

    end
    puts 'JobadderFieldMapping spec passed!'
  end
end