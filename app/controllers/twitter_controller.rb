class TwitterController < ApplicationController
  protect_from_forgery with: :null_session
  after_filter :setup_access_control_origin

  def index
    @setting = TwitterAppSetting.find_by dataset_id: params[:data][:dataset_id]
    create_settings if @setting.blank?

    app_id    = params[:data][:id]
    @client   = get_client if @setting.present? && @setting.access_token.present?
    @base_url = params[:data][:original_url]
    @authorize_url = "/users/auth/twitter?app_authentication=true&app_id=#{app_id}"
    @client_name   = @client.user.screen_name.dup.insert(0,'@') if @client.present?

    render layout: false
  rescue Twitter::Error::Unauthorized => e
    if e.to_s == 'Invalid or expired token.'
      @setting.destroy
      @setting = nil
    end
    Honeybadger.notify(e, force: true)
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

    if params[:job].present? && @setting.present? && @setting.access_token.present?
      unless @setting.only_featured? && params[:job][:hot] == false
        client = get_client
        tweet = parse_tweet(params)
        client.update(tweet)
      end
    end

  rescue Twitter::Error::Forbidden => e
    Honeybadger.notify(e, force: true)
  ensure
    render nothing: true, status: 200 and return
  end

  def update
    @setting = TwitterAppSetting.find_by dataset_id: params[:twitter_app_setting][:dataset_id]

    if @setting.update(params[:twitter_app_setting].permit!)
      flash[:notice] = "Settings successfully saved."
    else
      flash[:alert] = "Settings could not be saved. Please try again."
    end
  end

  def disable
    @setting = TwitterAppSetting.find_by dataset_id: params[:dataset_id]
    @setting.destroy

    redirect_to params[:callback]
  end

  private

  def create_settings
    TwitterAppSetting.create(dataset_id: params[:data][:dataset_id])
  end

  def parse_tweet(params)
    job = OpenStruct.new params[:job]
    discipline = params[:disciplines].first[:name] rescue ''

    tweet = "#{job.job_title} - #{job.job_location} - #{discipline} #{params[:job_url]}"

    if @setting.tweet.present?
      tweet = @setting.tweet
      tweet = tweet.gsub('{{job_title}}', job.job_title)
      tweet = tweet.gsub('{{job_location}}', job.job_location)
      tweet = tweet.gsub('{{discipline}}', discipline)
      tweet = tweet.gsub('{{job_url}}', params[:job_url])
    end

    tweet.gsub('-  -', '-')
  end

  def get_client
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_API_KEY']
      config.consumer_secret     = ENV['TWITTER_API_SECRET']
      config.access_token        = @setting.access_token
      config.access_token_secret = @setting.access_token_secret
    end
  end

end
