class TwitterController < ApplicationController
  protect_from_forgery with: :null_session
  after_filter :setup_access_control_origin
  
  def index
    @settings = TwitterAppSetting.find_by dataset_id: params[:data][:dataset_id]
    create_settings if @settings.blank?

    consumer  = OAuth::Consumer.new(
                 'fCVbggypYLV6lYKNG338Emj6N', 
                 'aZuJPIM8yTihW21apa6nO0XC00TeLY91ZWhAle9poVms1zLbfK',
                 site: 'https://api.twitter.com',
                 authorize_path: '/oauth/authenticate',
                 sign_in: true
               )

    app_id   = params[:data][:id]
    base_url = params[:data][:base_url]
    @request_token = consumer.get_request_token({ oauth_callback: "#{base_url}/admin/apps/#{app_id}/callback" })
    @authorize_url = @request_token.authorize_url

    render layout: false
  end
  
  def callback
    redirect_to index_url
  end

  private

  def create_settings
    TwitterAppSetting.create(dataset_id: params[:data][:dataset_id])
  end

end
