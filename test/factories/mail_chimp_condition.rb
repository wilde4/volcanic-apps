require 'faker'

FactoryGirl.define do

  factory :mail_chimp_condition do
    mail_chimp_app_settings {MailChimpAppSettings.last || FactoryGirl.create(:mail_chimp_app_settings)}
  end
end