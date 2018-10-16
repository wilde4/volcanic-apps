FactoryGirl.define do
  factory :jobadder_field_mapping do
    jobadder_app_setting_id 1
    jobadder_field_name 'email'
    registration_question_reference 'email'
    job_attribute 'job'
  end
end
