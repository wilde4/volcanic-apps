class ReedGlobalController < ApplicationController
  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  before_action :set_key, only: [:index]
  before_action :get_remote_data, except: [:job_disciplines, :activate_app, :deactivate_app]

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  def index
    @reed_countries = ReedCountry.where dataset_id: params[:data][:dataset_id]
    @reed_country = ReedCountry.new dataset_id: params[:data][:dataset_id]
    @reed_mapping = ReedMapping.new
    render layout: false
  end

  def create_country
    @reed_country = ReedCountry.new params[:reed_country].permit!
    if @reed_country.save
      flash[:notice] = "#{@reed_country.name} created."
      @reed_country = ReedCountry.new dataset_id: params[:reed_country][:dataset_id]
      @reed_mapping = ReedMapping.new
      @reed_countries = ReedCountry.where dataset_id: params[:reed_country][:dataset_id]
    else
      flash[:alert]  = "Country could not be created. Please try again."
    end
  end

  def destroy_country
    @reed_country = ReedCountry.find_by dataset_id: params[:dataset_id], id: params[:id]
    @reed_country.destroy
    @reed_countries = ReedCountry.where dataset_id: params[:dataset_id]
    @reed_country = ReedCountry.new dataset_id: params[:dataset_id]
    @reed_mapping = ReedMapping.new
    flash[:notice] = "#{@reed_country.name} deleted."
  end

  def create_mapping
    @reed_mapping = ReedMapping.new params[:reed_mapping].permit!
    if @reed_mapping.save
      flash[:notice] = "Mapping created."
      @country = @reed_mapping.reed_country
      @reed_country = ReedCountry.new dataset_id: params[:reed_mapping][:dataset_id]
      @reed_mapping = ReedMapping.new
      @reed_countries = ReedCountry.where dataset_id: params[:reed_mapping][:dataset_id]
    else
      flash[:alert]  = "Mapping could not be created. Please try again."
    end
  end

  def destroy_mapping
    @reed_mapping = ReedMapping.find_by reed_country_id: params[:reed_country_id], id: params[:id]
    @reed_mapping.destroy
    @country = @reed_mapping.reed_country
    @reed_countries = ReedCountry.where dataset_id: @country.dataset_id
    @reed_country = ReedCountry.new dataset_id: @country.dataset_id
    @reed_mapping = ReedMapping.new
    flash[:notice] = "Mapping deleted."
  end

  def job_disciplines
    @reed_countries = ReedCountry.where dataset_id: params[:dataset_id]
    job_functions = params[:job][:job_functions].split(',')
    country_reference = params[:job][:extra_categorisation]
    reed_country = @reed_countries.find_by country_reference: country_reference
    if reed_country.present?
      @job_functions = HTTParty.get("#{host_endpoint}/api/v1/job_functions.json?").parsed_response
      discipline_ids = job_functions.map do |jf|

        job_function = @job_functions.find { |job_function| job_function['id'] == jf.strip.to_i }
        job_function ||= @job_functions.find { |job_function| job_function['reference'] == jf.strip }

        if job_function.present?
          mappings = reed_country.mappings.where job_function_id: job_function['id']
          mappings.map(&:discipline_id) if mappings.present?
        end

      end.flatten.compact

      if discipline_ids.present?
        render json: { success: true, params: { discipline: discipline_ids.join(',') } }
      else
        render json: {}
      end
    else
      render json: {}
    end
  end

  private

  def host_endpoint
    if Rails.env.development?
      "http://awesome-recruitment.localhost.volcanic.co:3000"
    else
      "#{@key.protocol}#{@key.host}"
    end
  end

  def get_remote_data
    @disciplines = HTTParty.get("#{host_endpoint}/api/v1/disciplines.json?").parsed_response
    @job_functions = HTTParty.get("#{host_endpoint}/api/v1/job_functions.json?").parsed_response
  end


end
