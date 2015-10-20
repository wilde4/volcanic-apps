class FilteredNotificationsController < ApplicationController
  include Payloadable

  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin

  before_action :set_key, only: [:send_notification]

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

  def send_notification
    response = post_to_api("notifications", "trigger_single_notification", {user_id: 181126, notification: "filtered_job_announcement"})
    render json: { success: true }
  end

end