class V10SyncController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  before_filter :set_key, only: [:index, :save_job, :set_featured]

  def index
    @v10_sync_setting = V10SyncSetting.find_by(dataset_id: params[:data][:dataset_id]) || V10SyncSetting.new(dataset_id: params[:data][:dataset_id])


    render layout: false
  end

  def update

    @v10_sync_setting = V10SyncSetting.find_by(dataset_id: params[:v10_sync_setting][:dataset_id]) || V10SyncSetting.new(dataset_id: params[:v10_sync_setting][:dataset_id])

    if @v10_sync_setting.update(params[:v10_sync_setting].permit!)
      flash[:notice]  = "Settings successfully saved."
    else
      flash[:alert] = "Settings could not be saved. Please try again."
    end
  end

  def jobs
    @v10_sync_setting = V10SyncSetting.find_by(dataset_id: params[:dataset_id])
    render json: { "error"=> "not configured" } and return if @v10_sync_setting.blank? || @v10_sync_setting.endpoint.blank? || @v10_sync_setting.api_key.blank?

    job = params[:job].except(:id, :job_type_id, :views, :retired, :retired_at, :keyword_cache, :salary_hidden, :benefits, :exclusive_until, :salary_currency, :salary_benefits, :user_id, :extra, :paid, :homepage, :image_uid, :image_name)
    job_full_hash = params[:job_full_hash] || {}

    job[:job_type] = params[:job_type_reference]

    discipline_string = params[:disciplines].map{|d| d[:reference]}.join(',')
    job[:discipline] = discipline_string

    job_function_string = job_full_hash[:job_functions].map{|d| d[:reference]}.join(',')
    job[:job_functions] = job_function_string

    job[:salary_currency] = job_full_hash[:currency].try(:name)

    fetch_extra_data_ids(job, job_full_hash, params[:client_name])

    url = "#{@v10_sync_setting.endpoint}/api/v1/jobs.json"

    response = HTTParty.post(url, body: {job: job, api_key: @v10_sync_setting.api_key})

    if response.success?
      render json: { "success"=> "true" } and return
    else
      render json: { "error"=> "failed to post" } and return
    end
  end

  private

  def fetch_extra_data_ids(job_object, job_full_hash, client_name)
    url = "#{@v10_sync_setting.endpoint}/api/v1/available_job_attributes.json"
    response = HTTParty.get(url, query: {api_key: @v10_sync_setting.api_key})
    response_json = JSON.parse(response.body)
    # binding.pry
    (1..6).each do |x|
      next unless response_json["custom_#{x}"].try("values").present? && job_full_hash[:"custom_#{x}_values"].present?
      puts "custom_#{x}"
      new_ids = []
      job_full_hash[:"custom_#{x}_values"].each do |v9_val|
        puts v9_val
        new_ids << response_json["custom_#{x}"]["values"].select{|val| val["reference"] == v9_val[:reference]}.first["id"]
      end
      job_object[:"custom_#{x}"] = new_ids
    end

    if response_json["clients"].try("values").present? && client_name.present?
      job_object[:client_id] = response_json["clients"]["values"].select{|val| val["name"] == client_name}.first["id"]
    end
    true
  end

end