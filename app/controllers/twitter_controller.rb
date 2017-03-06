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

    job = OpenStruct.new params[:job]
    discipline = params[:disciplines].first[:name] rescue ''

    tweet = parse_tweet(job, discipline)
    client.update(tweet)

    render nothing: true, status: 200 and return
  end

  def update
    @setting = TwitterAppSetting.find_by dataset_id: params[:twitter_app_setting][:dataset_id]

    if @setting.update(params[:twitter_app_setting].permit!)
      flash[:notice]  = "Settings successfully saved."
    else
      flash[:alert]   = "Settings could not be saved. Please try again."
    end
    render nothing: true, status: 200 and return
  end

  private

  def create_settings
    TwitterAppSetting.create(dataset_id: params[:data][:dataset_id])
  end

  def parse_tweet(job, discipline)
    return "#{job.job_title} - #{job.job_location} - #{discipline}" unless @setting.tweet.present?
    tweet = @setting.tweet
    tweet = tweet.gsub('{{job_title}}', job.job_title)
    tweet = tweet.gsub('{{job_location}}', job.job_location)
    tweet = tweet.gsub('{{discipline}}', discipline)
    tweet
  end

end
