FactoryGirl.define do

  factory :gdpr_accepted, class: ArithonUser do
    user_id 1
    email 'johny@email.com'
    user_data {{'id' => 1, 'dataset_id' => 3}}
    user_profile {{'first_name' => 'Johny', 'last_name' => 'Apple', 'upload_name' => 'test_name',
                   'upload_path' => 'www.example.com/files/123456', }}
    registration_answers {{'fav_color' => 'black', 'fav_fruit' => 'durian', 'fav_number' => 6}}
    legal_documents {[
        {
            'key' => 'cookies',
            'title' => 'Cookie Policy',
            'version' => 1.0,
            'consented' => false,
            'consent_type' => 'explicit',
            'consented_at' => 'null'
        },
        {
            'key' => 'term_and_conditions',
            'title' => 'Terms & Conditions',
            'version' => 1.0,
            'consented' => true,
            'consent_type' => 'implied',
            'consented_at' => '2018-08-12 14=>40=>34 UTC'
        },
        {
            'key' => 'privacy_policy',
            'title' => 'GDPR Policy',
            'version' => 1.4,
            'consented' => true,
            'consent_type' => 'implied',
            'consented_at' => '2018-08-12 14=>40=>34 UTC'
        }
    ]}
  end

  factory :gdpr_not_accepted, class: ArithonUser  do
    user_id 1
    email 'johny@email.com'
    user_data {{'id' => 1, 'dataset_id' => 3}}
    user_profile {{'first_name' => 'Johny', 'last_name' => 'Apple', 'upload_name' => 'test_name',
                   'upload_path' => 'www.example.com/files/123456', }}
    registration_answers {{'fav_color' => 'black', 'fav_fruit' => 'durian', 'fav_number' => 6}}
    legal_documents {[
        {
            'key' => 'cookies',
            'title' => 'Cookie Policy',
            'version' => 1.0,
            'consented' => false,
            'consent_type' => 'explicit',
            'consented_at' => 'null'
        },
        {
            'key' => 'term_and_conditions',
            'title' => 'Terms & Conditions',
            'version' => 1.0,
            'consented' => true,
            'consent_type' => 'implied',
            'consented_at' => '2018-08-12 14=>40=>34 UTC'
        },
        {
            'key' => 'privacy_policy',
            'title' => 'GDPR Policy',
            'version' => 1.4,
            'consented' => false,
            'consent_type' => 'implied',
            'consented_at' => '2018-08-12 14=>40=>34 UTC'
        }
    ]}
  end

  factory :gdpr_not_presented, class: ArithonUser do
    user_id 1
    email 'johny@email.com'
    user_data {{'id' => 1, 'dataset_id' => 3}}
    user_profile {{'first_name' => 'Johny', 'last_name' => 'Apple', 'upload_name' => 'test_name',
                   'upload_path' => 'www.example.com/files/123456', }}
    registration_answers {{'fav_color' => 'black', 'fav_fruit' => 'durian', 'fav_number' => 6}}
    legal_documents {[
        {
            'key' => 'cookies',
            'title' => 'Cookie Policy',
            'version' => 1.0,
            'consented' => false,
            'consent_type' => 'explicit',
            'consented_at' => 'null'
        },
        {
            'key' => 'term_and_conditions',
            'title' => 'Terms & Conditions',
            'version' => 1.0,
            'consented' => true,
            'consent_type' => 'implied',
            'consented_at' => '2018-08-12 14=>40=>34 UTC'
        }
    ]}
  end

end