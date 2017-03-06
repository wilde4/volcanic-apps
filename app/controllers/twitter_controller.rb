class TwitterController < ApplicationController
  protect_from_forgery with: :null_session
  after_filter :setup_access_control_origin

  def index
    @setting = TwitterAppSetting.find_by dataset_id: params[:data][:dataset_id]
    create_settings if @setting.blank?

    app_id   = params[:data][:id]
    @authorize_url = "/users/auth/twitter?app_authentication=true&app_id=#{app_id}"

    render layout: false
  end
  
  def callback
    @setting = TwitterAppSetting.find_by dataset_id: params[:data][:dataset_id]

    data = params[:data]
    @setting.update_attributes(access_token: data[:access_token], access_token_secret: data[:access_token_secret])

    respond_to do |format|
      format.json { render json: { success: true, message: 'Updated App Settings.' } }
    end
  end

  def post_tweet
    @setting = TwitterAppSetting.find_by dataset_id: params[:dataset_id]

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_API_KEY']
      config.consumer_secret     = ENV['TWITTER_API_SECRET']
      config.access_token        = @setting.access_token
      config.access_token_secret = @setting.access_token_secret
    end
    client.update("I'm tweeting with @gem!!!")

    render nothing: true, status: 200 and return
  end

  private

  def create_settings
    TwitterAppSetting.create(dataset_id: params[:data][:dataset_id])
  end

end
