class TextLocalController < ApplicationController

  def send_sms
    # bf7ed87a9fbed9c7e590c8038ba300ec3bd96749
    @user = JSON.parse(params[:user]) if params[:user]
    @hook = JSON.parse(params[:hook]) if params[:hook]
    @settings = JSON.parse(params[:settings]) if params[:settings]
  
    requested_url = 'http://api.txtlocal.com/send/?'
  
    uri = URI.parse(requested_url)
    http = Net::HTTP.start(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
   
    res = Net::HTTP.post_form(uri, 'username' => @settings['email'], 'hash' => @settings['key'], 'message' => @settings['message'], 'sender' => @settings['sender'], 'numbers' => '07871548440')
    response = JSON.parse(res.body)
  
    respond_to do |format|
      if response["status"] == "success"
        format.json { render :json => { :status => "all_ok", :message => "SMS has been sent successfully." } }
      else
        format.json { render :json => { :status => "error" } }
      end
    end
  end
  
end





