module ProfileSetup
  extend ActiveSupport::Concern

  # Allow sites to perform POST with XmlHttpRequest to the app server
  # Use 'after_filter' to access this
  # Development should point to http://<site>.localhost.volcanic.co:3000
  # Production should point to the Marketing Automation server
  def setup_access_control_origin
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Origin'] = '*'
  end


  def activate_app
    @profile = Profile.find_by(app_dataset_id: params[:data][:app_dataset_id])

    if !@profile.present?
      @profile = Profile.new
      @profile.host = params[:data][:host]
      @profile.app_dataset_id = params[:data][:app_dataset_id]
      @profile.api_key = params[:data][:api_key]
    end

    @profile.enable = true
    @profile.api_key = params[:data][:api_key]

    respond_to do |format|
        format.json { render json: { success: @profile.save }}
    end
  end


  def deactivate_app
    profile = Profile.where(app_dataset_id: params[:data][:app_dataset_id]).first
    profile.enable = false
    respond_to do |format|
      if profile.save
        format.json { render json: { success: 'Profile has been disabled.' }}
      else
        format.json { render json: { error: 'Profile not found.' } }
      end
    end
  end


  protected

    def set_profile
      if params[:data].present?
        app_dataset_id = params[:data][:dataset_id]
      end

      @profile = Profile.find_by(app_dataset_id: app_dataset_id)
      render nothing: true, status: 401 and return if @profile.blank?
    end


end
