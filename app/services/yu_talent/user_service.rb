require 'uri'
require 'open-uri'
require 'base64'
require 'oauth2'

class YuTalent::UserService < BaseService

  API_ENDPOINT = "https://www.yutalent.co.uk/c/oauth/v1?method="

  def initialize(user)
    @user         = user
    @user_type    = @user.user_data['user_type']
    @dataset_id   = @user.user_data['dataset_id']
    @access_token = set_access_token
  end


  def save_user
    begin
      @yutalent_id = check_duplicates
      return if @yutalent_id.present?
      # map contact attributes
      @contact_attributes               = map_contact_attributes
      @contact_attributes[:project_id]  = project_id
      @contact_attributes[:status_id]   = status_id('new')
      @contact_attributes[:type]        = type_id(@user_type)
      # post contact attributes
      @response = @access_token.post(URI.decode(API_ENDPOINT + "contacts/add"), body: @contact_attributes)
      @response_body = JSON.parse(@response.body)
      # update user details
      if @response_body['id'].present?
        @user.update(
          yu_talent_uid: @response_body['id'],
          project_id:    @contact_attributes[:project_id],
          status_id:     @contact_attributes[:status_id],
          type_id:       @contact_attributes[:type]
        )
      end
    rescue => e
      Rails.logger.info "--- yu:talent save_user exception ----- : #{e.message}"
    end
  end


  private

    def set_access_token
      @client             = YuTalent::AuthenticationService.client
      @settings           = YuTalentAppSetting.find_by(dataset_id: @dataset_id)
      @access_token_hash  = JSON.parse(@settings.try(:access_token))
      @access_token       = OAuth2::AccessToken.from_hash(@client, @access_token_hash)
      return @access_token
    end


    def check_duplicates
      begin
        if @user.yu_talent_uid.present?
          yutalent_id = @user.yu_talent_uid
        else
          @response = @access_token.get(URI.decode(API_ENDPOINT + "contacts/check-duplicates"), body: { 'email' => @user.email })
          @duplicate_contacts = JSON.parse(@response.body)
          if @duplicate_contacts.count > 0
            Rails.logger.info '--- yu:talent DUPLICATE CANDIDATE RECORD FOUND'
            @response_body  = JSON.parse(@response.body)
            @last_candidate = @response_body.last
            yutalent_id     = @last_candidate.id
          else
            yutalent_id = nil
          end
        end
      rescue => e
        Rails.logger.info "--- yu:talent check_duplicates exception ----- : #{e.message}"
      end
    end


    def status_id(status = 'new')
      @response       = @access_token.get(URI.decode(API_ENDPOINT + 'statuses/list'))
      @response_body  = JSON.parse(@response.body)
      @status_id      = "default_1" #defaults to new
      @response_body.map do |s|
        @status_id    = s['id'] if s['status'].try(:downcase) == status.try(:downcase)
      end
      return @status_id
    end


    def type_id(type = 'candidate')
      # maps to yu:talent category_id
      @response       = @access_token.get(URI.decode(API_ENDPOINT + 'contacts/categories'))
      @response_body  = JSON.parse(@response.body)
      @type_id        = nil
      @response_body.map do |t|
        @type_id      = t['id'] if t['name'].try(:downcase) == type.try(:downcase)
      end
      return @type_id
    end


    def project_id
      @response       = @access_token.get(URI.decode(API_ENDPOINT + 'projects/list'))
      @response_body  = JSON.parse(@response.body)
      @project        = @response_body.last
      return @project['id']
    end


    def map_contact_attributes
      @attributes                       = Hash.new
      @attributes[:data]                = Hash.new
      @attributes[:data][:name]         = candidate_name
      @attributes[:data][:email]        = @user.email
      @attributes[:data][:background_info] = linkedin_background_info if @user.linkedin_profile.present?
      # @attributes[:data][:company_website] =
      @attributes[:data][:company_name] = @user.registration_answers['companyName'] if @user.registration_answers['companyName'].present?
      @attributes[:data][:location]     = @user.registration_answers['desiredLocations'] if @user.registration_answers['desiredLocations'].present?
      @attributes[:data][:history]      = linkedin_work_history if @user.linkedin_profile.present?
      @attributes[:data][:education]    = linkedin_education_history if @user.linkedin_profile.present?
      @attributes[:data][:facebook]     = @user.user_profile['facebook_url'] if @user.user_profile['facebook_url'].present?
      @attributes[:data][:linkedin]     = @user.user_profile['li_publicProfileUrl'] if @user.user_profile['li_publicProfileUrl'].present?
      @attributes[:data][:phone]        = @user.registration_answers['telephone-number'] if @user.registration_answers['telephone-number'].present?
      @attributes[:data][:phone_mobile] = @user.registration_answers['mobile-telephone-number'] if @user.registration_answers['mobile-telephone-number'].present?
      @attributes[:data][:position]     = @user.registration_answers['occupation'] if @user.registration_answers['occupation'].present?
      @attributes[:data][:cv]           = base64_encoder(@user.user_profile['upload_path']) if @user.user_profile['upload_path'].present?
      @attributes[:data][:avatar]       = base64_encoder(@user.user_profile['li_pictureUrl']) if @user.user_profile['li_pictureUrl'].present?
      return @attributes
    end


    def candidate_name
      # format candidate name
      @first_name = @user.user_profile['first_name']
      @last_name  = @user.user_profile['last_name']
      if @first_name.present? && @last_name.present?
        "#{@last_name} #{@last_name}"
      else
        "#{@last_name}" || "#{@last_name}"
      end
    end


    def base64_encoder(path)
      @host             = Key.find_by(app_dataset_id: @dataset_id).try(:host)
      @url              = URI.decode('http://' + @host + path)
      @resource         = open(@url).read
      @encoded_resource = Base64.encode64(@resource)
      return @encoded_resource
    end


    def linkedin_background_info
      linkedin_education_history
      linkedin_skills
      linkedin_work_history
    end


    def linkedin_work_history
       !@user.linkedin_profile['positions'].present?
      if @user.linkedin_profile['positions'].size > 0
        string              = string + '<h3>PREVIOUS EXPERIENCE</h3>'
        @user.linkedin_profile['positions'].each do |position|
          string            = string + '<p>'
          company_name      = position['company_name'].present? ? 'Company: ' + position['company_name'] + '<br />' : "Company: N/A<br />"
          title             = position['title'].present? ? 'Position: ' + position['title'] + '<br />' : "Position: N/A<br />"
          start_date        = position['start_date'].present? ? 'Start Date: ' + position['start_date'] + '<br />' : "Start Date: N/A<br />"
          end_date          = position['end_date'].present? ? 'End Date: ' + position['end_date'] + '<br />' : "End Date: N/A<br />"
          summary           = position['summary'].present? ? 'Summary: ' + position['summary'] + '<br />' : "Summary: N/A<br />"
          company_industry  = position['company_industry'].present? ? 'Company Industry: ' + position['company_industry'] + '<br />' : "Company Industry: N/A<br />"
          string            = string + company_name + title + start_date + end_date + summary + company_industry + '</p>'
        end
        return string
      end
    end


    def linkedin_education_history
      unless !@user.linkedin_profile['education_history'].present?
        if @user.linkedin_profile['education_history'].size > 0
          string            = string + '<h3>EDUCATION</h3>'
          @user.linkedin_profile['education_history'].each do |education|
            string          = string + '<p>'
            string          = string + education['school_name'] + '<br />' unless education['school_name'].blank?
            field_of_study  = education['field_of_study'].present? ? 'Field of Study: ' + education['field_of_study'] + '<br />' : "Field of Study: N/A<br />"
            start_date      = education['start_date'].present? ? 'Start Date: ' + education['start_date'] + '<br />' : "Start Date: N/A<br />"
            end_date        = education['end_date'].present? ? 'End Date: ' + education['end_date'] + '<br />' : "End Date: N/A<br />"
            degree          = education['degree'].present? ? 'Degree: ' + education['degree'] + '<br />' : "Degree: N/A<br />"
            activities      = education['activities'].present? ? 'Activities: ' + education['activities'] + '<br />' : "Activities: N/A<br />"
            notes           = education['notes'].present? ? 'Notes: ' + education['notes'] + '<br />' : "Notes: N/A<br />"
            string          = string + field_of_study + start_date + end_date + degree + activities + notes + '</p>'
          end
          return string
        end
      end
    end


    def linkedin_skills
      unless !@user.linkedin_profile['skills'].present?
        if @user.linkedin_profile['skills'].size > 0
          string        = string + '<h3>SKILLS</h3>'
          @user.linkedin_profile['skills'].each do |skill|
            string      = string + '<p>'
            skill_name  = skill['skill'].present? ? 'Skill: ' + skill['skill'] + '<br />' : "Skill: N/A<br />"
            proficiency = skill['proficiency'].present? ? 'Proficiency: ' + skill['proficiency'] + '<br />' : "Proficiency: N/A<br />"
            years       = skill['years'].present? ? 'Years: ' + skill['years'] + '<br />' : "Years: N/A<br />"
            string      = string + skill_name + proficiency + years + '</p>'
          end
          return string
        end
      end
    end

end
