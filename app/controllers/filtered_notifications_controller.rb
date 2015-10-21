class FilteredNotificationsController < ApplicationController
  include Payloadable

  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin

  before_action :set_key, only: [:send_notification]

  after_filter :setup_access_control_origin, only: [:modal_content]

  layout false

  def app_notifications
    notifications = { filtered_job_announcement: {
                        description: "Custom Emails are sent by this",
                        targets: [:user, :custom],
                        tags: [:name]
                      }
                    }

    respond_to do |format|
      format.json { render json: notifications }
    end
  end

  def job_form

  end

  def send_notification
    # response = post_to_api("notifications", "trigger_single_notification", {user_id: 181126, notification: "filtered_job_announcement"})
    if params[:job].present? && params[:job][:extra].present? and params[:job][:extra][:filtered_notifications].present?

      client_ids = params[:job][:extra][:filtered_notifications][:client_ids]

      if client_ids.is_a?(Array)

        response = post_to_api("notifications", "trigger_clients_notification", {client_ids: client_ids, notification: "filtered_job_announcement"})
      end
      # 485 482

    end
    render json: { success: true }
  end

  def modal_content

    data = {}

    @clients = HTTParty.get("http://jobsatteam.localhost.volcanic.co:3000/api/v1/clients/search.json", body: data)

    render json: {success: true, content: render_to_string("modal_content.html") }
  end

end