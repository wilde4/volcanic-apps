require 'rails_helper'

describe Jobadder::AuthenticationService do

  before(:each) do

    @key = create(:app_key)

    @ja_setting  = create(:jobadder_app_setting)

    @user =  create(:jobadder_user)

    @ja_setting_attr = attributes_for(:jobadder_app_setting)

  end


  context 'When testing the Jobadder::AuthenticationService ' do

    it 'should pass create authentication service client' do

      client = Jobadder::AuthenticationService.client(@ja_setting)

      expect(client).not_to be_nil
      expect(client).to be_instance_of(OAuth2::Client)

    end

    it 'should pass construct authorize url' do

      redirect  = JobadderHelper.callback_url

      urls = JobadderHelper.authentication_urls

      auth_url = Jobadder::AuthenticationService.authorize_url( @ja_setting_attr[:dataset_id], @ja_setting)

      expect(auth_url).to eql("#{urls[:authorize]}?access_type=offline&client_id=#{ENV['JOBADDER_CLIENT_ID']}&redirect_uri=#{redirect}&response_type=code&scope=read+write+offline_access&state=#{@ja_setting_attr[:dataset_id]}")

    end

    puts 'Jobadder::AuthenticationService spec passed!'

  end

end