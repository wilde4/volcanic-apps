class MailChimpController < ApplicationController
  protect_from_forgery with: :null_session
  before_filter :set_key, only: [:index, :callback, :new_condition]
  after_filter :setup_access_control_origin
  
  def index
    @host = @key.host
    @app_id = params[:data][:id]
    @new_condition_url = create_url(@app_id,@host,'new_condition')
    
    @auth_url = MailChimp::AuthenticationService.client_auth(@app_id, @host)
    @settings = MailChimpAppSettings.find_by(dataset_id: params[:data][:dataset_id])
    
    @mailchimp_conditions = @settings.mail_chimp_conditions
    
    # @user_groups_url = 'http://' + @host + ':3000' + '/api/v1/user_groups.json'
    @user_groups_url = 'http://meridian.dev.volcanic.co/api/v1/user_groups.json'

    @user_groups = HTTParty.get(@user_groups_url)
    
    
    render layout: false
  end
  
  def callback
    @attributes                       = Hash.new
    @attributes[:dataset_id]          = params[:data][:dataset_id]
    @attributes[:authorization_code]  = params[:data][:code]
    @attributes[:access_token]        = MailChimp::AuthenticationService.get_access_token(
                                          params[:data][:id],
                                          @key.host,
                                          params[:data][:code])
                                          
    unless !@attributes[:access_token].present?
      @settings = MailChimpAppSettings.find_by(dataset_id: @attributes[:dataset_id])
      if @settings.present?
        if @settings.update(@attributes)
          flash[:notice]  = "App successfully authorised."
        else
          flash[:alert]   = "App could not be authorised."
        end
      else
        @settings = MailChimpAppSettings.new(@attributes)
        if @settings.save
          flash[:notice]  = "App successfully authorised."
        else
          flash[:alert]   = "App could not be authorised."
        end
      end
    end

    render :index, layout: false
  end
  
  def new_condition
    @mail_chimp_app_settings = MailChimpAppSettings.find_by(dataset_id: @key.app_dataset_id)
    @mail_chimp_condition = MailChimpCondition.new
    
    # @user_groups_url = 'http://' + @host + ':3000' + '/api/v1/user_groups.json'
    @user_groups_url = 'http://meridian.dev.volcanic.co/api/v1/user_groups.json'
    @user_groups = HTTParty.get(@user_groups_url)
    @user_group_collection = []
    @user_groups.each do |g|
      @user_group_collection << [g['name'],g['id']]
    end
    
    gibbon = set_gibbon('d82e45856f225b103b668b15c4b6e874-us13')
    mailchimp_lists = gibbon.lists.retrieve
    @mailchimp_lists_collection = []
    mailchimp_lists['lists'].each do |list|
      @mailchimp_lists_collection << [list['name'], list['id']]
    end
    
    render layout: false
  end
  
  def save_condition
    condition_attributes = Hash.new
    condition_attributes[:mail_chimp_app_settings_id]    = params[:mail_chimp_condition][:mail_chimp_app_settings_id]
    condition_attributes[:user_group]                    = params[:mail_chimp_condition][:user_group]
    condition_attributes[:mail_chimp_list_id]            = params[:mail_chimp_condition][:mail_chimp_list_id]
    condition_attributes[:registration_question_id]      = params[:mail_chimp_condition][:registration_question_id]
    condition_attributes[:answer]                        = params[:mail_chimp_condition][:answer]
    
    @mailchimp_condition = MailChimpCondition.new(condition_attributes)
    
    host = Key.find(params[:key_id]).host
    index_url = create_url(params[:app_id], host, 'index')
    
    if @mailchimp_condition.save
      flash[:notice]  = "Condition succesfully created"
      redirect_to index_url
    else
      render json: { success: false, status: "Error: #{@mailchimp_condition.errors.full_messages.join(', ')}" }
    end
    
  end
  
  private
    
    def create_url(app_id, host, endpoint)
      @host = format_url(host)
      "#{@host}/admin/apps/#{app_id}/#{endpoint}"
    end
    
    def format_url(url)
      url = URI.parse(url)
      return url if url.scheme
      return "http://#{url}:3000" if Rails.env.development?
      "http://#{url}"
    end 
    
    def set_gibbon(access_token)
      return gibbon = Gibbon::Request.new(api_key: access_token)
    end
  
end






