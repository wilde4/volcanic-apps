class CandidateSharingController < ApplicationController
  include Payloadable

  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin

  before_action :set_key, only: [:send_notification, :app_notifications]

  layout false


  def app_notifications

    puts "\n\n App Notifications from VA \n\n"

    notifications = { filtered_candidate_announcement: {
                        description: "a Candidate is shared",
                        targets: [:user, :custom],
                        tags: [:'client.name', :'client.phone_number', :'user.name'],
                        team_shared_candidate: true
                      }
                    }

    respond_to do |format|
      format.json { render json: notifications }
    end
  end


  def send_notification

    puts "\n\n Sending Notification from VA Candidate Sharing \n\n"
    
    if params[:user].present? && params[:user][:extra].present? and params[:user][:extra][:filtered_notifications].present?
      client_ids = params[:user][:extra][:filtered_notifications][:client_ids]
      if client_ids.is_a?(Array)
        FilteredNotificationSending.create(user_id: params[:user][:id], client_ids: client_ids)
        response = post_to_api("notifications", "trigger_clients_notification", {client_ids: client_ids, notification: "filtered_candidate_announcement", user_id: params[:user][:id]})
      end   
    end
    render json: { success: true }
  end
end
