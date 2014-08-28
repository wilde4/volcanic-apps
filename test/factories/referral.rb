require 'faker'

FactoryGirl.define do

  factory :referral do
    sequence(:user_id) { |n| n }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    referred_by { user_id - 1 }
  end
end
