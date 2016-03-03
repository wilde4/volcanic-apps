class ServicedottController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json, :xml

  # http://localhost:3001/servicedott/email_data.json?user[email]=bob@foo.com&user[created_at]=2014-02-11T10:01:07.000+00:00&user_profile[first_name]=Bob&user_profile[last_name]=Hoskins&job[job_title]=Testing Job&job[job_reference]=ABC123&email_name=apply_for_vacancy
  def email_data
    @user = params[:user]
    @user_profile = params[:user_profile]
    @name = [@user_profile['first_name'], @user_profile['last_name']].join(' ')
    @registration_answer_hash = params[:registration_answer_hash]
    @job = params[:job]

    if params[:email_name] == 'apply_for_vacancy'
      # BUILD XML
      xml_string = render_to_string(action: 'email_data.xml.builder', layout: false)
      # RETURN XML DIRECTLY
    end
    render json: { success: true, xml_string: xml_string }
    # render xml: xml_string
  end
end
