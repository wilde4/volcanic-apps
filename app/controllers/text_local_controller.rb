class TextLocalController < ApplicationController
  protect_from_forgery with: :null_session

  def send_sms
    # bf7ed87a9fbed9c7e590c8038ba300ec3bd96749
    # @user = JSON.parse(params[:user]) if params[:user]
    # @hook = JSON.parse(params[:hook]) if params[:hook]
    # @settings = JSON.parse(params[:settings]) if params[:settings]
    @settings = params[:settings]
    message = @settings[:message]
    # message = 'Welcome to Evergrad! Click here to download the Evergrad iOS app: http://bbc.co.uk'
  
    requested_url = 'http://api.txtlocal.com/send/?'
  
    uri = URI.parse(requested_url)
    # http = Net::HTTP.start(uri.host, uri.port)
    # request = Net::HTTP::Get.new(uri.request_uri)

    mobile = params[:registration_answer_hash][@settings["mobile_registration_question_reference"].to_sym]
    numbers = mobile.present? ? mobile : '07811197374'

    log = TextLocalLog.find_by(user_id: params[:user][:id], mobile_number: mobile)

    unless log.present?
      new_log = TextLocalLog.new(user_id: params[:user][:id], mobile_number: mobile, message: message, sender: @settings['sender'])
      res = Net::HTTP.post_form(uri, 'username' => @settings['email'], 'hash' => @settings['key'], 'message' => message, 'sender' => @settings['sender'], 'numbers' => numbers)
      response = JSON.parse(res.body)
      logger.info "--- response = #{response.inspect}"
  
      respond_to do |format|
        if response["status"] == "success"
          new_log.save
          format.json { render :json => { :status => "success", :message => "SMS has been sent successfully." } }
        else
          format.json { render :json => { :status => "error" } }
        end
      end
    else
      respond_to do |format|
        format.json { render :json => { :status => "success", :message => "SMS not sent." } }
      end
    end
  end
  
end





