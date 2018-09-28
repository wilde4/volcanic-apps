require 'rails_helper'

describe Jobadder::ClientService do

  before(:each) do
    JobadderAppSetting.delete_all

  end

  after(:each) do
    JobadderAppSetting.delete_all
  end



  key = Key.create(app_dataset_id: 1, app_name: 'jobadder')

  ja_setting = JobadderAppSetting.create(:dataset_id => 1,
                                          :app_url => 'www.example.com')

  ja_setting = JobadderAppSetting.new({dataset_id: 1,
                                       ja_client_id: '12345',
                                       ja_client_secret: '6789',
                                       app_url: 'www.example.com'})
  ja_service = Jobadder::ClientService.new(ja_setting)

  context 'When testing the Jobadder::ClientService' do
    it 'should pass something' do

    end
  end

end