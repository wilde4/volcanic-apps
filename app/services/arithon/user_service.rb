require 'uri'
require 'open-uri'
require 'base64'
require 'oauth2'
require 'rest-client'
require 'mimemagic'
require 'mimemagic/overlay'

class Arithon::UserService < BaseService
    API_ENDPOINT =  "http://eu-arithon-com-z3bo3ff0cjp4.runscope.net/ArithonAPI.php"
    # API_ENDPOINT = "http://requestb.in/1doqnnf1"


  def initialize(user, settings, key)
    @user         = user
    @key = key
    if @user.user_data['user_group_name'].present?
      @user_group_name    = @user.user_data['user_group_name']
    else
      @user_group_name    = @user.user_data['user_type']
    end
    @dataset_id   = @user.user_data['dataset_id']
    if Rails.env.development?
        @company_name = "API Test"
        @api_key = ENV['ARITHON_DEV_KEY']
    else
      @api_key = settings["authorization_code"]
      @company_name = settings["company_name"]
    end
  end

  def save_user
    Rails.logger.info "--- ABOUT TO INSERT"
    @new_cv = true
    @new_avatar = true
    @contact_attributes               = map_contact_attributes
    # Rails.logger.info "--- @contact_attributes 4: #{@contact_attributes}"
    @response = send_request("PushCandidate", @contact_attributes)
    delete_tmp_cv_file
    Rails.logger.info "--- @response: #{@response.inspect}"
    
    # update user details
    Rails.logger.info "--- Updating Arithon ID"
    if arithon_uid = get_arithon_uid
      Rails.logger.info "--- arithon_uid: #{arithon_uid}"
      @user.update arithon_uid: arithon_uid
    end
  rescue => e
    Rails.logger.info "--- arithon save_user exception ----- : #{e.message}"
  end

  def update_user
    Rails.logger.info "--- ABOUT TO UPDATE"
    # map contact attributes
    Rails.logger.info "--- ABOUT TO map_contact_attributes"
    @contact_attributes               = map_contact_attributes
    @contact_attributes[:candidateID] = @user.arithon_uid
    Rails.logger.info "--- @contact_attributes = #{@contact_attributes.inspect}"
    # post contact attributes
    @response = send_request("PushCandidate", @contact_attributes)
    delete_tmp_cv_file
    Rails.logger.info "--- @response = #{@response.inspect}"
    # update user details
  rescue => e
    Rails.logger.info "--- arithon update_user exception ----- : #{e.message}"
  end

  def get_arithon_uid
    Rails.logger.info "--- STARTING get_arithon_uid"

    @attributes2 = Hash.new
    @attributes2[:email] = @user.email
    @attributes2[:candidateName] = candidate_name
    # Rails.logger.info "--- @attributes2: #{@attributes2.inspect}"
    @response = send_request("CandidateDetails", @attributes2)
    # Rails.logger.info "--- @response: #{@response.present? ? @response.inspect : ''}"
    if @response.present? && @response["count"].present? && @response["count"] > 0
      Rails.logger.info '--- arithon CANDIDATE RECORD FOUND'
      @last_candidate = @response["records"].last
      # Rails.logger.info "--- @last_candidate: #{@last_candidate.inspect}"
      arithon_id     = @last_candidate["candidateID"]
    else
      arithon_id = nil
    end
    return arithon_id
  rescue => e
    Rails.logger.info "--- arithon get_arithon_uid exception ----- : #{e.message}"
  end


  private
    
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
      FileUtils.rm_rf(user_id_tmp_folder_path) if File.directory?(user_id_tmp_folder_path) && user_id_tmp_folder_path.include?("/tmp/arithon_cvs")
    end

    def send_request(command, data=nil)
      request = Hash.new
      request[:authorise] = { key: @api_key, company: @company_name }
      request[:request] = { command: command }
      request[:request][:data] = data if data.present?
      if command == "PushCandidate" && cv_up_loads_checks?  
        build_tmp_cv_file
        request[:request][:data].merge!(file_info_hash) if data.present?
        @response =  RestClient.post(API_ENDPOINT, file_request_hash(request)) # All responses from API return a 200, even those that fail, actual response code is sent in body
      else
        @response =  HTTParty.post(API_ENDPOINT, { body: request }) # All responses from API return a 200, even those that fail, actual response code is sent in body
      end      
      @response
    end
    
    def file_request_hash(request)
      if mime_type_is_ok?
        { authorise: request[:authorise], request: request[:request], attachedFile: file_to_attach }
      else
        { authorise: request[:authorise], request: request[:request] }
      end
    end
    
    def accepted_mime_types
      [
        'text/plain',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/html',
        'application/rtf',
        'application/x-rtf',
        'text/richtext',
        'application/vnd.oasis.opendocument.text'
      ]
    end
    
    def file_info_hash
      if mime_type_is_ok?
        {file: { name: upload_name, type: cv_mime_type }}
      else
        {}
      end
    end
    
    def file_to_attach
      if mime_type_is_ok?
        tmp_cv_file.rewind
        tmp_cv_file
      else
        ""
      end
    end
    
    def mime_type_is_ok?
      @mime_type_is_ok ||= accepted_mime_types.include?(cv_mime_type)
    end
      
    
    def tmp_cv_file
      @tmp_cv_file ||= File.open(tmp_cv_path)
    end
    
    def cv_mime_type
      if File.exist?(tmp_cv_path)
        @cv_mime_type ||= MimeMagic.by_path(tmp_cv_path).type 
      else
        ""
      end
    end

    def map_contact_attributes
      # Rails.logger.info "--- STARTING map_contact_attributes"
      @attributes                 = Hash.new
      @attributes[:candidateName] = candidate_name
      @attributes[:email]         = @user.email
      @attributes = @attributes
      # Rails.logger.info "--- FINISHED map_contact_attributes: #{@attributes.inspect}"
      return @attributes
    end

    def candidate_name
      # format candidate name
      @first_name = @user.user_profile['first_name'].try(:strip)
      @last_name  = @user.user_profile['last_name'].try(:strip)
      if @first_name.present? && @last_name.present?
        "#{@first_name} #{@last_name}"
      else
        "#{@first_name}" || "#{@last_name}"
      end
    end

end
