# require 'faker'
#
# FactoryGirl.define do
#
#   user_data_hash = {"id" => 1, "dataset_id" => 1}
#   user_profile_data_hash = {"first_name" => "John", "last_name" => "Doe"}
#   registration_answers_hash = {"question" => "how are you", "answer" => "good"}
#
#   factory :jobadder_user do
#     user_id 1
#     email Faker::Internet.email
#     user_data user_data_hash
#     user_profile user_profile_data_hash
#     registration_answers registration_answers_hash
#     linkedin_profile nil
#     legal_documents nil
#     sent_upload_ids [1,2,3]
#
#   end
# end
