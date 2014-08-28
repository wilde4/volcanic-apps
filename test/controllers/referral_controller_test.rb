require 'test_helper'

class ReferralControllerTest < ActionController::TestCase

  setup do
    create_list(:referral, 100)
  end

  def teardown
    Referral.delete_all
  end

  test "should return token for new record" do
    get :create_referral, {format: :json, user: {'id' => 1},
        user_profile: {'first_name' => 'John', 'last_name' => 'Smith'}}

    assert_response :success
    response = JSON.parse(@response.body)

    assert_not_nil @response
    assert response['success']
    assert_match /[[:xdigit:]]{8}/, response['referral_token']
  end

  test "should get a referral for an id" do
    get :get_referral, {format: :json, id: 1}

    assert_response :success
    response = JSON.parse(@response.body)

    assert_not_nil @response
    assert response['success']

    #verify the correct data is saved by cmp with source
    referral = Referral.first
    assert_equal referral.first_name, response['referral']['first_name']
    assert_equal referral.last_name, response['referral']['last_name']
    assert_equal referral.token, response['referral']['token']
  end

  test "should get all users referred by a user" do
    get :get_referred, {format: :json, id: 2}

    assert_response :success
    response = JSON.parse(@response.body)

    assert_not_nil @response

    assert response['success']
    assert_equal 1, response['count']
    assert_equal response['referrals'][0]['user_id'], 1
  end

  test "should confirm a referral" do
    get :confirm, {format: :json, id: 1}

    assert_response :success
    response = JSON.parse(@response.body)

    assert_not_nil @response
  end

end
