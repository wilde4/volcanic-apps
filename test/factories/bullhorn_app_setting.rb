require 'faker'

FactoryGirl.define do

  factory :bullhorn_app_setting do
    dataset_id 123
    bh_username ENV["BH_USERNAME"]
    bh_password ENV["BH_PASSWORD"]
    bh_client_id ENV["BH_CLIENT_ID"]
    bh_client_secret ENV["BH_CLIENT_SECRET"]
    source_text 'TEST SOURCE'
    linkedin_bullhorn_field 'customText11'
  end
end
