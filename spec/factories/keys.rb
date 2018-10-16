FactoryGirl.define do
  factory :app_key, class: Key do
    app_dataset_id 2
    app_name 'jobadder'
    protocol 'http://'
    host 'test.localhost.volcanic.co'
  end
end