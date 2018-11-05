FactoryGirl.define do

  factory :jobadder_user do
    user_id 1
    email 'johny@email.com'
    user_data {{'id' => 1, 'dataset_id' => 2}}
    user_profile {{'first_name' => 'Johny', 'last_name' => 'Apple', 'upload_name' => 'test_name',
                   'upload_path' => 'www.example.com/files/123456', }}
    registration_answers {{'fav_color' => 'black', 'fav_fruit' => 'durian', 'fav_number' => 6}}
    sent_upload_ids [1, 2, 3]
  end
end