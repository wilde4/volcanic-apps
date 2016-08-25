class FilteredNotificationsController < ApplicationController
  include Payloadable

  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin

  before_action :set_key, only: [:send_notification, :job_form, :app_notifications, :shared_candidate_form]

  after_filter :setup_access_control_origin, only: [:modal_content]

  layout false

  def app_notifications
    extra_keys = []
    if Key.find_by(app_dataset_id: @key.app_dataset_id, app_name: "split_fee").present?
      extra_keys = [:"split_fee.amount", :"split_fee.percentage", :"split_fee.terms"]
    end

    tags = [:name, :job_title, :job_link, :"job.job_location", :"job.job_description", :"job.salary_low", :"job.salary_high", :"job.salary_free", :"job.contact_name", :"job.contact_email", :"job.client_name", :"job.client_phone_number", :"job.client_email"].concat(extra_keys)

    notifications = { filtered_job_announcement: {
                        description: "a Filtered Notification is sent",
                        targets: [:user, :custom],
                        tags: tags
                      }
                    }

    respond_to do |format|
      format.json { render json: notifications }
    end
  end

  def job_form

  end

  def shared_candidate_form

  end

  def send_notification
    # response = post_to_api("notifications", "trigger_single_notification", {user_id: 181126, notification: "filtered_job_announcement"})
    if params[:job].present? && params[:job][:extra].present? and params[:job][:extra][:filtered_notifications].present?
      client_ids = params[:job][:extra][:filtered_notifications][:client_ids]
      if client_ids.is_a?(Array)
        FilteredNotificationSending.create(job_id: params[:job][:id], client_ids: client_ids)
        response = post_to_api("notifications", "trigger_clients_notification", {client_ids: client_ids, notification: "filtered_job_announcement", job_id: params[:job][:id]})
      end      
    elsif params[:user].present? && params[:user][:extra].present? and params[:user][:extra][:filtered_notifications].present?
      client_ids = params[:user][:extra][:filtered_notifications][:client_ids]
      if client_ids.is_a?(Array)
        # FilteredNotificationSending.create(job_id: params[:job][:id], client_ids: client_ids)
        response = post_to_api("notifications", "trigger_clients_notification", {client_ids: client_ids, notification: "filtered_candidate_announcement", user_id: params[:user][:id]})
      end   
    end
    render json: { success: true }
  end

  def modal_content
    data = Hash.new
    if params[:job].present?
      disciplines = params[:job][:discipline_ids]
      key_locations = params[:job][:key_location_ids]
      # puts disciplines
      data[:discipline_id] = disciplines.reject { |e| e.to_s.empty? }.join("|") if disciplines.present?
      data[:secondary_key_location_id] = key_locations.reject { |e| e.to_s.empty? }.join("|") if key_locations.present?
      data[:search_origin] = "filtered_notifications"
      data[:per_page] = 1000

      if params[:job][:extra][:filtered_notifications].present?
        dataset_id = params[:job][:extra][:filtered_notifications][:dataset_id]

        @key = Key.where(app_dataset_id: dataset_id, app_name: "filtered_notifications").first
      end

      @clients = HTTParty.get("http://#{@key.host}/api/v1/clients/search.json", body: data) if @key.present?
    elsif params[:user].present?
      disciplines = params[:user][:discipline_ids]
      data[:discipline_id] = disciplines.reject { |e| e.to_s.empty? }.join("|") if disciplines.present?
      data[:key_location] = []
      data[:search_origin] = "filtered_notifications"
      data[:per_page] = 1000

      if params[:user][:extra][:filtered_notifications].present?
        dataset_id = params[:user][:extra][:filtered_notifications][:dataset_id]

        @key = Key.where(app_dataset_id: dataset_id, app_name: "filtered_notifications").first
      end

      @clients = HTTParty.get("http://#{@key.host}/api/v1/clients/search.json", body: data) if @key.present?
    end



    render json: {success: true, content: render_to_string("modal_content.html") }
  end

end