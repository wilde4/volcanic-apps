require 'uri'
require 'open-uri'
require 'base64'
require 'oauth2'
require 'rest-client'
require 'mimemagic'
require 'mimemagic/overlay'

class Arithon::UserService < BaseService
  API_ENDPOINT = Rails.env.development? ? "http://dev3-vi.arithon.com/ArithonAPI.php" : "http://eu.arithon.com/ArithonAPI.php"
  # API_ENDPOINT = "http://requestb.in/1doqnnf1"


  def initialize(user, settings, key)
    @user = user
    @key = key
    if @user.user_data['user_group_name'].present?
      @user_group_name = @user.user_data['user_group_name']
    else
      @user_group_name = @user.user_data['user_type']
    end
    @dataset_id = @user.user_data['dataset_id']
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
    @contact_attributes = map_contact_attributes
    # Rails.logger.info "--- @contact_attributes 4: #{@contact_attributes}"
    @response = send_request("PushCandidate", @contact_attributes)
    Rails.logger.info "--- @response: #{@response.inspect}"

    # update user details
    Rails.logger.info "--- Updating Arithon ID"
    if arithon_uid = get_arithon_uid
      Rails.logger.info "--- arithon_uid: #{arithon_uid}"
      @user.update arithon_uid: arithon_uid
    end
  rescue => e
    @user.app_logs.create key: @key, name: 'save_user', response: "Exception: #{e.message}", error: true, internal: true
    Rails.logger.info "--- arithon save_user exception ----- : #{e.message}"
  end

  def update_user
    Rails.logger.info "--- ABOUT TO UPDATE"
    # map contact attributes
    Rails.logger.info "--- ABOUT TO map_contact_attributes"
    @contact_attributes = map_contact_attributes
    @contact_attributes[:candidateID] = @user.arithon_uid
    Rails.logger.info "--- @contact_attributes = #{@contact_attributes.inspect}"
    # post contact attributes
    @response = send_request("PushCandidate", @contact_attributes)
    Rails.logger.info "--- @response = #{@response.inspect}"
      # update user details
  rescue => e
    @user.app_logs.create key: @key, name: 'update_user', response: "Exception: #{e.message}", error: true, internal: true
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
      arithon_id = @last_candidate["candidateID"]
    else
      arithon_id = nil
    end
    return arithon_id
  rescue => e
    @user.app_logs.create key: @key, name: 'get_arithon_uid', response: "Exception: #{e.message}", error: true, internal: true
    Rails.logger.info "--- arithon get_arithon_uid exception ----- : #{e.message}"
  end


  private

  def build_tmp_cv_file

    # Save file into tempfile from S3
    uri = URI.parse(cv_path)
    io = uri.open
    encoding = io.read.encoding
    Rails.logger.info " --- Encoding: #{encoding}"
    filename_array = upload_name.split('.')
    extension = filename_array.pop
    filename = filename_array.join('.')
    @tmp_cv_file = Tempfile.new(["#{filename}-", ".#{extension}"], Rails.root.join('tmp'), encoding: encoding).tap do |f|
      io.rewind
      f.write(io.read)
    end
    @tmp_cv_file.rewind


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
    @tmp_cv_file.close
    @tmp_cv_file.unlink
  end

  def send_request(command, data = nil)
    request = Hash.new
    request[:authorise] = {key: @api_key, company: @company_name}
    request[:request] = {command: command}
    request[:request][:data] = data if data.present?
    if command == "PushCandidate" && cv_up_loads_checks?
      build_tmp_cv_file
      request[:request][:data].merge!(file_info_hash) if data.present?
      @response = JSON.parse(RestClient.post(API_ENDPOINT, file_request_hash(request))) # All responses from API return a 200, even those that fail, actual response code is sent in body
      @user.app_logs.create key: @key, name: command, endpoint: API_ENDPOINT, message: file_request_hash(request).to_s, response: @response.to_s, error: @response["code"] != 200
      delete_tmp_cv_file
    else
      @response = HTTParty.post(API_ENDPOINT, {body: request}) # All responses from API return a 200, even those that fail, actual response code is sent in body
      @user.app_logs.create key: @key, name: command, endpoint: API_ENDPOINT, message: {body: request}.to_s, response: @response.to_s, error: @response["code"] != 200
    end
    @response
  end

  def file_request_hash(request)
    if mime_type_is_ok?
      {authorise: request[:authorise], request: request[:request], attachedFile: @tmp_cv_file}
    else
      {authorise: request[:authorise], request: request[:request]}
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
        'text/richtext'
    ]
  end

  def file_info_hash
    if mime_type_is_ok?
      {file: {name: @tmp_cv_file.path.split('/').last, type: cv_mime_type}}
    else
      {}
    end
  end

  def mime_type_is_ok?
    if accepted_mime_types.include?(cv_mime_type)
      @mime_type_is_ok ||= true
    else
      @user.app_logs.create(key: @key, name: 'mime_type_is_ok?', response: "CV mime type:#{cv_mime_type} not accepted", error: true, internal: true) if @mime_type_is_ok.nil?
      @mime_type_is_ok ||= false
    end
  end

  def cv_mime_type
    if @tmp_cv_file.present?
      @cv_mime_type ||= MimeMagic.by_path(@tmp_cv_file.path).type rescue ""
    else
      ""
    end
  end

  def map_contact_attributes
    # Rails.logger.info "--- STARTING map_contact_attributes"
    @attributes = Hash.new
    @attributes[:candidateName] = candidate_name
    @attributes[:email] = @user.email
    #Find GDPR legal document in array
    legal_document = @user.legal_documents.find {|ld| ld['key'] == 'privacy_policy'}
    unless legal_document.nil?
      legal_document['consented'] === true ? @attributes[:gdprAccept] = 'Yes' : @attributes[:gdprAccept] = 'No'
    end

    @attributes = @attributes
    # Rails.logger.info "--- FINISHED map_contact_attributes: #{@attributes.inspect}"
    return @attributes
  end

  def candidate_name
    # format candidate name
    @first_name = @user.user_profile['first_name'].try(:strip)
    @last_name = @user.user_profile['last_name'].try(:strip)
    if @first_name.present? && @last_name.present?
      "#{@first_name} #{@last_name}"
    else
      "#{@first_name}" || "#{@last_name}"
    end
  end

end
