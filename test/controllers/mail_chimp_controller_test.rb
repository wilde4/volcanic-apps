require 'test_helper'

class MailChimpControllerTest < ActionController::TestCase
  setup do
    @mailchimp_settings = FactoryGirl.create :mail_chimp_app_settings
    @key = FactoryGirl.create :key
    @condition = FactoryGirl.create :mail_chimp_condition
  end
  
  test "should create condition" do
    assert_difference('MailChimpCondition.count') do
      post :save_condition, mail_chimp_condition: { mail_chimp_app_settings_id: @mailchimp_settings.id }, key_id: @key.id
    end
  end
  
  test "should destroy condition" do
    assert_difference('MailChimpCondition.count', -1) do
      delete :delete_condition, id: @condition, key_id: @key.id
    end
  end
end
