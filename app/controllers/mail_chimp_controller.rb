class MailChimpController < ApplicationController

  def export_list
    @users = JSON.parse(params[:users]) if params[:users]
    @settings = JSON.parse(params[:settings]) if params[:settings]
    gb = Gibbon::API.new(@settings["key"])
    @batch = @users.collect{|user|{:email => {:email => user["email"]}, :merge_vars => {:FNAME => user["first_name"], :LNAME => user["last_name"]}}}
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






