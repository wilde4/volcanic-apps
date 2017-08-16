class Api::V1::ProfilesController <  Api::BaseController

  protect_from_forgery with: :null_session

  include ProfileSetup
  
  after_filter :setup_access_control_origin
  before_action :set_profile, only: [:index]

end
