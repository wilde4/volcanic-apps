class MailChimpController < ApplicationController
  protect_from_forgery with: :null_session
  before_filter :set_key, only: [:index]
  after_filter :setup_access_control_origin
  
  def index
    @host = @key.host
    @app_id = params[:data][:id]
    
    @auth_url = MailChimp::AuthenticationService.client_auth(@app_id, @host)
    @settings = MailChimpAppSettings.find_by(dataset_id: params[:data][:dataset_id])
    render layout: false
  end

  def export_list
    @users = JSON.parse(params[:users]) if params[:users]
    @settings = JSON.parse(params[:settings]) if params[:settings]
    gb = Gibbon::API.new(@settings["key"])
    # @batch = @users.collect{|user|{:email => {:email => user["email"]}, :merge_vars => {:FNAME => user["first_name"], :LNAME => user["last_name"]}}}
    
    @batch = @users.collect{|user|{:email => {:email => (user["email"] rescue nil)}, 
                                   :merge_vars => {
                                     :FNAME => (user["li_entry"].split("\n")[3].gsub("firstName:", "").strip rescue nil), 
                                     :LNAME => (user["li_entry"].split("\n")[7].gsub("lastName:", "").strip rescue nil) }}}
    
    response = gb.lists.batch_subscribe(:id => @settings["list_key"], :batch => @batch, :double_optin => false, :update_existing => true)
    respond_to do |format|
      if response["error_count"] > 0
        format.json { render :json => { :status => "error" } }
      else
        format.json { render :json => { :status => "all_ok", :message => "List has been updated successfully." } }
      end
    end
  end
  
end






