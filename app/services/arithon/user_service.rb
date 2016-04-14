require 'uri'
require 'open-uri'
require 'base64'
require 'oauth2'
require 'rest-client'

class Arithon::UserService < BaseService
  
  if Rails.env.development?
    API_ENDPOINT = "http://requestb.in/1emt2rm1" 
  else
    API_ENDPOINT =  "http://eu-arithon-com-z3bo3ff0cjp4.runscope.net/ArithonAPI.php"
  end

  def initialize(user, settings, key)
    @user         = user
    @key = key
    if @user.user_data['user_group_name'].present?
      @user_group_name    = @user.user_data['user_group_name']
    else
      @user_group_name    = @user.user_data['user_type']
    end
    @dataset_id   = @user.user_data['dataset_id']
    @api_key = settings["authorization_code"]
    @company_name = settings["company_name"]
  end

  def save_user
    begin
      Rails.logger.info "--- ABOUT TO INSERT"
      @new_cv = true
      @new_avatar = true
      @contact_attributes               = map_contact_attributes
      # Rails.logger.info "--- @contact_attributes 4: #{@contact_attributes}"
      @response = send_request("PushCandidate", @contact_attributes)
      # Rails.logger.info "--- @response: #{@response.inspect}"
      # update user details
      if @response['code'] == 200
        # API doesn't return ID of new record so we have to fetch it
        @attrs = Hash.new
        @attrs[:email] = @user.email
        @attrs[:candidateName] = candidate_name
        @response2 = send_request("CandidateDetails", @attrs)
        if @response2['code'] == 200
          Rails.logger.info "--- @response2: #{@response2.inspect}"
          @user.update(
            arithon_uid: @response2['records'][0]['candidateID']
          )
        end
      end
    rescue => e
      Rails.logger.info "--- arithon save_user exception ----- : #{e.message}"
    end
  end

  def update_user
    begin
      Rails.logger.info "--- ABOUT TO UPDATE"
      # map contact attributes
      Rails.logger.info "--- ABOUT TO map_contact_attributes"
      @contact_attributes               = map_contact_attributes
      @contact_attributes[:candidateID] = @user.arithon_uid
      Rails.logger.info "--- @contact_attributes = #{@contact_attributes.inspect}"
      # post contact attributes
      @response = send_request("PushCandidate", @contact_attributes)
      Rails.logger.info "--- @response = #{@response.inspect}"
      # update user details
    rescue => e
      Rails.logger.info "--- arithon update_user exception ----- : #{e.message}"
    end
  end

  def check_duplicates
    Rails.logger.info "--- STARTING check_duplicates"
    begin
      if @user.arithon_uid.present?
        arithon_id = @user.arithon_uid
      else
        @dup_attributes = Hash.new
        @dup_attributes[:email] = @user.email
        @dup_attributes[:candidateName] = candidate_name
        # Rails.logger.info "--- @dup_attributes: #{@dup_attributes.inspect}"
        @response = send_request("CandidateDetails", @dup_attributes)
        # Rails.logger.info "--- @response: #{@response.inspect}"
        if @response["count"] > 0
          Rails.logger.info '--- arithon DUPLICATE CANDIDATE RECORD FOUND'
          @last_candidate = @response["records"].last
          # Rails.logger.info "--- @last_candidate: #{@last_candidate.inspect}"
          arithon_id     = @last_candidate["candidateID"]
        else
          arithon_id = nil
        end
      end
      return arithon_id
    rescue => e
      Rails.logger.info "--- arithon check_duplicates exception ----- : #{e.message}"
    end
  end


  private
    
    def add_cv_file(attr_hash)
      if cv_up_loads_checks?
        attr_hash.merge!({file: { name: upload_name, type: upload_name.split('.').last }})
      else
        attr_hash
      end
    end
    
    def build_tmp_cv_file
      make_dir
      File.open(tmp_cv_path, "wb") do |file|
        file.write(open(cv_path).read)
      end
    end
    
    def cv_tmp_folder
      @cv_tmp_folder ||= "#{Rails.root}/tmp/arithon_cvs"
    end
    
    def make_dir
      FileUtils.mkdir_p(user_id_tmp_folder_path) unless File.directory?(user_id_tmp_folder_path)
    end
    
    
    def tmp_cv_path
      @tmp_cv_path ||= "#{user_id_tmp_folder_path}/#{upload_name}"
    end
    
    def user_id_tmp_folder_path
     @user_id_tmp_folder_path ||= "#{cv_tmp_folder}/#{@user.user_data['id']}"
    end
    
    def cv_path
      if Rails.env.development?
        @cv_path ||= 'http://' + @key.host + upload_path
      else
        # UPLOAD PATHS USE CLOUDFRONT URL
        @cv_path ||= upload_path
      end
    end
    
    def upload_name
      @upload_name ||= @user["user_profile"]["upload_name"]
    end
    
    def upload_path
      @upload_path ||= @user["user_profile"]["upload_path"]
    end
    
    def cv_up_loads_checks?
      @user["user_profile"].present? && upload_name.present? && upload_path.present?
    end
    
    def delete_tmp_cv_file
      File.delete(tmp_cv_path) if File.exist?(tmp_cv_path)
      FileUtils.rm_rf(user_id_tmp_folder_path) if File.directory?(user_id_tmp_folder_path)
    end
    
    def send_request(command, data=nil)
      request = Hash.new
      request[:authorise] = { key: @api_key, company: @company_name }
      request[:request] = { command: command }
      request[:request][:data] = data if data.present?
      if command == "PushCandidate" && cv_up_loads_checks?  
        build_tmp_cv_file
        @response =  RestClient.post(API_ENDPOINT, { body: request, attachedFile: File.open(tmp_cv_path) }) # All responses from API return a 200, even those that fail, actual response code is sent in body
      else
        @response =  HTTParty.post(API_ENDPOINT, { body: request }) # All responses from API return a 200, even those that fail, actual response code is sent in body
      end      
      delete_tmp_cv_file
    end

    def map_contact_attributes
      # Rails.logger.info "--- STARTING map_contact_attributes"
      @attributes                 = Hash.new
      @attributes[:candidateName] = candidate_name
      @attributes[:email]         = @user.email
      @attributes = add_cv_file(@attributes)
      # Rails.logger.info "--- FINISHED map_contact_attributes: #{@attributes.inspect}"
      return @attributes
    end

    def candidate_name
      # format candidate name
      @first_name = @user.user_profile['first_name']
      @last_name  = @user.user_profile['last_name']
      if @first_name.present? && @last_name.present?
        "#{@first_name} #{@last_name}"
      else
        "#{@first_name}" || "#{@last_name}"
      end
    end

end
