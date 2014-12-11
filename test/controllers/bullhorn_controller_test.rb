require 'test_helper'

# MAKING SURE BULLHORN CONTROLLER WORKS
class BullhornControllerTest < ActionController::TestCase
  test 'test should create user' do
    assert_difference('BullhornUser.count') do
      post(
        :save_user,
        user: {
          id: 123,
          email: 'test@example.com'
        },
        user_profile: { first_name: 'Frank', last_name: 'Bruno' },
        registration_answer_hash: { blah: 'foo', bar: 'blah' }
      )
    end
    assert_response :success
  end
end
