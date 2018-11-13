FactoryGirl.define do
  factory :app_key, class: Key do
    app_dataset_id 2
    app_name 'jobadder'
    protocol 'http://'
    host 'test.localhost.volcanic.co'
    api_key 'abc123'
  end

  factory :arithon_app_key, class: Key do
    app_dataset_id 3
    app_name 'arithon'
    protocol 'http://'
    host 'test.localhost.volcanic.co'
  end
end