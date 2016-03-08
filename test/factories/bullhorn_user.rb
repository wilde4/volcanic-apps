require 'faker'

FactoryGirl.define do

  factory :bullhorn_user do
    user_id 12345
    email 'test@example.com'
    bullhorn_uid 175873
  end
end