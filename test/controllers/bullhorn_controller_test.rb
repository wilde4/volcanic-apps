require 'test_helper'

# MAKING SURE BULLHORN CONTROLLER WORKS
class BullhornControllerTest < ActionController::TestCase
  setup do
    FactoryGirl.create :bullhorn_field_mapping
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'dateOfBirth', registration_question_reference: 'birth-date'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'address1', registration_question_reference: 'address1'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'address2', registration_question_reference: 'address2'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'city', registration_question_reference: 'city'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'state', registration_question_reference: 'county'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'zip', registration_question_reference: 'post-code'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'countryID', registration_question_reference: 'country'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'employmentPreference', registration_question_reference: 'job-type'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'occupation', registration_question_reference: 'job-title'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'salary', registration_question_reference: 'desired-salary'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'companyName', registration_question_reference: 'company'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'gender', registration_question_reference: 'gender'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'salaryLow', registration_question_reference: 'current-salary'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'customText1', registration_question_reference: 'current-package'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'customText4', registration_question_reference: 'notice-period'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'dayRateLow', registration_question_reference: 'current_day_rate'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'dayRate', registration_question_reference: 'desired_day_rate'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'dateAvailable', registration_question_reference: 'availability'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'customTextBlock1', registration_question_reference: 'leaving-reason'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'mobile', registration_question_reference: 'mobile'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'phone', registration_question_reference: 'phone'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'businessSectors', registration_question_reference: 'sector'
    FactoryGirl.create :bullhorn_field_mapping, bullhorn_field_name: 'category', registration_question_reference: 'category'
  end

  test 'test should create user' do
    assert_difference('BullhornUser.count') do
      post(
        :save_user,
        user: {
          id: 123,
          email: 'test@volcanic.co.uk',
          dataset_id: 123
        },
        user_profile: { first_name: 'TEST2', last_name: 'TEST2' },
        registration_answer_hash: { 
          'another-email' => 'test@example.com',
          'companyName' => 'VolcanicUK',
          'birth-date' => '1987-04-22',
          'address1' => 'c/o Volcanic',
          'address2' => '232 Manchester Road',
          'city' => 'Stockport',
          'county' => 'Cheshire',
          'post-code' => 'SK4 1NN',
          'country' => 'United Kingdom',
          'job-type' => 'Permanent',
          'job-title' => 'Ruby Tester',
          'desired-salary' => '66666',
          'company' => 'Volcanic TEST',
          'gender' => 'M',
          'current-salary' => '50000',
          'current-package' => 'Dental & Eyes',
          'notice-period' => '2 Months',
          'current_day_rate' => '300',
          'desired_day_rate' => '500',
          'availability' => '2016-01-01',
          'leaving-reason' => 'Fed up of work environment',
          'mobile' => '07898765432',
          'phone' => '0161 413 6424',
          'sector' => 'Energy / Utilities / Mining / Oil & Gas',
          'category' => 'Procurement / Buying / Purchasing'
        }
      )
    end
    assert_response :success
  end
end
