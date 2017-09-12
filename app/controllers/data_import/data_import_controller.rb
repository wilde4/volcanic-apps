class DataImport::DataImportController < ActionController::Base
  layout "data_import"
  include ProfileSetup

  skip_before_action :authenticate_profile!
  before_action :set_profile, only: :index

  def index
    @host = host_url
    render layout: false
  end

  private

    def host_url
      if Rails.env == "production"
        "https://#{ENV['DOMAIN_NAME']}"
      elsif Rails.env == "development"
        "http://localhost:3001"
      end
    end

end
