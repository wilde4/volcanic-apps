require 'faker'

FactoryGirl.define do

  factory :key do
    app_dataset_id 1 #fake app_dataset_id, should come from oliver params
    host 'localhost'
    api_key 'asdf12345'
    app_name 'app_name_test'
  end
end