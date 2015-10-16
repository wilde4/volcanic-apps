require 'faker'

FactoryGirl.define do

  factory :bullhorn_field_mapping do
    bullhorn_app_setting {BullhornAppSetting.last || FactoryGirl.create(:bullhorn_app_setting)}
    bullhorn_field_name 'email2'
    registration_question_reference 'another-email'
    sync_from_bullhorn true
  end
end
