require 'open-uri'
require 'base64'

class YuTalent::UserService < BaseService

  URL = "https://www.yutalent.co.uk/c/oauth/v1?method="

  def initialize(dataset_id, user, params)
    raise StandardError, "No user found!" if user.nil?
    raise StandardError, "No params found!" if params.nil?
    @dataset_id = dataset_id
    @user = user
    @params = params
  end


  def post_user
    # begin
      @refresh_token = YuTalentAppSetting.find_by(dataset_id: @dataset_id).try(:refresh_token)
      Rails.logger.info "--- refresh_token ----- : #{@refresh_token}"
      @contact = map_contact_attributes # create contact object
      @access_token = YuTalent::AuthenticationService.get_access_token(@refresh_token)
      @contact =  map_contact_attributes

      Rails.logger.info "--- access_token ----- : #{@access_token}"

      yt_user_id = get_yu_talent_id(@access_token) # GET YuTalent ID

      if yt_user_id.present?
        Rails.logger.info "--- UPDATING #{yt_user_id}: #{attributes.inspect} ..."
        # responce = HTTParty.post("contacts/add&access_token=7437643937328", body: @contact.to_json), headers: {"Authorization" => "Token token=\"#{@client}\""})
        response = HTTParty.post(URL + "contacts/add", body: @contact.to_json, headers: {"Authorization" => "Token token=\"#{@access_token}\""})
      else
        Rails.logger.info "--- CREATING CANDIDATE: #{attributes.inspect} ..."
        @user.update(yu_talent_uid: response['changedEntityId'])
      end
    # rescue => e
    #   puts e.inspect
    # end
  end


  private


    def map_contact_attributes

      puts "== params == #{@user.inspect}"
      attributes = Hash.new
      attributes[:status_id] = 1
      attributes[:project_id] = 123
      attributes[:type] = 45
      attributes[:data] = Hash.new
      attributes[:data][:name] = candidate_name
      # attributes[:data][:background_info] =
      # attributes[:data][:company_name] = @user.registration_answers[settings[:companyName]] if @user.registration_answers[settings[:companyName]].present?
      # attributes[:data][:company_website] =
      attributes[:data][:email] = @user.email
      # attributes[:data][:location] = @user.registration_answers[settings[:desiredLocations]] if @user.registration_answers[settings[:desiredLocations]].present?
      # attributes[:data][:history] = linkedin_work_history if @user.linkedin_profile.present?
      # attributes[:data][:education] = linkedin_education_history if @user.linkedin_profile.present?
      # attributes[:data][:facebook] = @user.user_profile[:facebook_url] if @user.user_profile[:facebook_url].present?
      # attributes[:data][:linkedin] = @user.user_profile[:li_publicProfileUrl] if @user.user_profile[:li_publicProfileUrl].present?
      # attributes[:data][:phone] = @user.registration_answers[settings[:phone]] if @user.registration_answers[settings[:phone]].present?
      # attributes[:data][:phone_mobile] = @user.registration_answers[settings[:mobile]] if @user.registration_answers[settings[:mobile]].present?
      # attributes[:data][:position] = @user.registration_answers[settings[:occupation]] if @user.registration_answers[settings[:occupation]].present?
      # attributes[:data][:cv] = base64_cv if @user.user_profile[:upload_path].present?
      # attributes[:data][:avatar] = base64_avatar if @user.user_profile[:li_pictureUrl].present?
      return attributes
    end


    def candidate_name
      if @user.user_profile[:first_name].present? && @user.user_profile[:last_name].present?
        "#{@user.user_profile[:first_name]} #{@user.user_profile[:last_name]}"
      else
        "#{@user.user_profile[:first_name]}" || "#{@user.user_profile[:last_name]}"
      end
    end


    def base64_cv
      key = Key.where(app_dataset_id: @params[:dataset_id]).first
      cv_url = 'http://' + key.host + @user.user_profile[:upload_path]
      cv = open(cv_url).read
      base64_cv = Base64.encode64(cv)
      return base64_cv
    end


    def base64_avatar
      key = Key.where(app_dataset_id: @params[:dataset_id]).first
      avatar_url = 'http://' + key.host + @user.user_profile[:li_pictureUrl]
      avatar = open(avatar_url).read
      base64_avatar = Base64.encode64(avatar)
      return base64_avatar
    end


    def check_duplicates
      if @user.yu_talent_uid.present?
        yu_talent_id = @user.yu_talent_uid
      else
        response = @access_token.post(URL + "contacts/check-duplicates", body: { 'email' => @user.email })
        Rails.logger.info "--- response = #{response.inspect}"
        if response.record_count.to_i > 0
          logger.info '--- CANDIDATE RECORD FOUND'
          last_candidate = response.body.last
          yu_talent_id = last_candidate.id
          @user.update(yu_talent_uid: yu_talent_id)
        else
          Rails.logger.info '--- CANDIDATE RECORD NOT FOUND'
          yu_talent_id = nil
        end
      end
    end


    def linkedin_work_history
      if @user.linkedin_profile['positions'].size > 0
        string = string + '<h3>PREVIOUS EXPERIENCE</h3>'
        @user.linkedin_profile['positions'].each do |position|
          string = string + '<p>'

          company_name = position['company_name'].present? ? 'Company: ' + position['company_name'] + '<br />' : "Company: N/A<br />"
          title = position['title'].present? ? 'Position: ' + position['title'] + '<br />' : "Position: N/A<br />"
          start_date = position['start_date'].present? ? 'Start Date: ' + position['start_date'] + '<br />' : "Start Date: N/A<br />"
          end_date = position['end_date'].present? ? 'End Date: ' + position['end_date'] + '<br />' : "End Date: N/A<br />"
          summary = position['summary'].present? ? 'Summary: ' + position['summary'] + '<br />' : "Summary: N/A<br />"
          company_industry = position['company_industry'].present? ? 'Company Industry: ' + position['company_industry'] + '<br />' : "Company Industry: N/A<br />"

          string = string + company_name + title + start_date + end_date + summary + company_industry + '</p>'
        end
      end
    end


    def linkedin_education_history
      if @user.linkedin_profile['education_history'].size > 0
        string = string + '<h3>EDUCATION</h3>'
        @user.linkedin_profile['education_history'].each do |education|
          string = string + '<p>'
          string = string + education['school_name'] + '<br />' unless education['school_name'].blank?

          field_of_study = education['field_of_study'].present? ? 'Field of Study: ' + education['field_of_study'] + '<br />' : "Field of Study: N/A<br />"
          start_date = education['start_date'].present? ? 'Start Date: ' + education['start_date'] + '<br />' : "Start Date: N/A<br />"
          end_date = education['end_date'].present? ? 'End Date: ' + education['end_date'] + '<br />' : "End Date: N/A<br />"
          degree = education['degree'].present? ? 'Degree: ' + education['degree'] + '<br />' : "Degree: N/A<br />"
          activities = education['activities'].present? ? 'Activities: ' + education['activities'] + '<br />' : "Activities: N/A<br />"
          notes = education['notes'].present? ? 'Notes: ' + education['notes'] + '<br />' : "Notes: N/A<br />"

          string = string + field_of_study + start_date + end_date + degree + activities + notes + '</p>'
        end
      end
    end


end
