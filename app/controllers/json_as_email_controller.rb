class JsonAsEmailController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json, :xml

  after_filter :setup_access_control_origin

  # http://localhost:3001/prs/email_data.json?user[email]=bob@foo.com&user[created_at]=2014-02-11T10:01:07.000+00:00&user_profile[first_name]=Bob&user_profile[last_name]=Hoskins&job[job_title]=Testing Job&job[job_reference]=ABC123&email_name=apply_for_vacancy&target_type=job_application
  def email_data
    email_names = params['settings']['email_names'].split(',').map(&:strip) rescue []
    target_types = params['settings']['target_types'].split(',').map(&:strip) rescue []

    if params['email_name'] && email_names.include?(params['email_name'])
      if params['target_type'].blank? || params['target_type'].present? && target_types.include?(params['target_type'])
        @keys = params['settings']['keys'].split(',').map(&:strip)
        body =  render_to_string(action: 'email_data.html.haml', layout: false)
        render json: { success: true, body: body }
      else
        render nothing: true, status: 404
      end
    else
      render nothing: true, status: 404
    end
  end
end
