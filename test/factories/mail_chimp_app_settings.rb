require 'faker'

FactoryGirl.define do

  factory :mail_chimp_app_settings do
    dataset_id 1 #fake dataset, should come from oliver when the app is activated
  end
end