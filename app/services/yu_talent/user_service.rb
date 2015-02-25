class YuTalent::UserService < BaseService

  def initialize(user, params)
    raise StandardError, "No user found!" if user.nil?
    raise StandardError, "No params found!" if params.nil?
    @user = user
    @client = YuTalent::ClientService.new(params)
  end


  def post_user
    # create contact object
    contact = map_contact_attributes

    # GET YuTalent ID
    yu_talent_id = get_yu_talent_id

    # CREATE user/candidate
    if yu_talent_id.present?
      logger.info "--- UPDATING #{yu_talent_id}: #{attributes.inspect} ..."
      response = @client.update_candidate(yu_talent_id, attributes.to_json)
      logger.info "--- response = #{response.inspect}"
    else
      logger.info "--- CREATING CANDIDATE: #{attributes.inspect} ..."
      response = @client.create_candidate(attributes.to_json)
      @user.update(bullhorn_uid: response['changedEntityId'])
    end
  end


  private


    def map_contact_attributes
      attributes = Hash.new
      attributes[:status_id] = 1
      attributes[:project_id] = 123
      attributes[:type] = 45
      attributes[:data] = Hash.new
      attributes[:data][:name] = candidate_name
      # attributes[:data][:background_info] =
      attributes[:data][:company_name] = @user.registration_answers[settings[:companyName]] if @user.registration_answers[settings[:companyName]].present?
      # attributes[:data][:company_website] =
      attributes[:data][:email] = @user.email
      attributes[:data][:location] = @user.registration_answers[settings[:desiredLocations]] if @user.registration_answers[settings[:desiredLocations]].present?
      attributes[:data][:history] = linkedin_description if @user.linkedin_profile.present?
      attributes[:data][:education] = @user.registration_answers[settings[:educationDegree]] if @user.registration_answers[settings[:educationDegree]].present?
      attributes[:data][:facebook] = @user.user_profile[:facebook_url] if @user.user_profile[:facebook_url].present?
      attributes[:data][:linkedin] = @user.user_profile[:li_publicProfileUrl] if @user.user_profile[:li_publicProfileUrl].present?
      attributes[:data][:phone] = @user.registration_answers[settings[:phone]] if @user.registration_answers[settings[:phone]].present?
      attributes[:data][:phone_mobile] = @user.registration_answers[settings[:mobile]] if @user.registration_answers[settings[:mobile]].present?
      attributes[:data][:position] = @user.registration_answers[settings[:occupation]] if @user.registration_answers[settings[:occupation]].present?
      # attributes[:data][:cv] =
      attributes[:data][:avatar] = @user.user_profile[:li_pictureUrl] if @user.user_profile[:li_pictureUrl].present?
      return attributes
    end


    def candidate_name
      if @user.user_profile[:first_name].present? && @user.user_profile[:last_name].present?
        "#{@user.user_profile[:first_name]} #{@user.user_profile[:last_name]}"
      else
        "#{@user.user_profile[:first_name]}" || "#{@user.user_profile[:last_name]}"
      end
    end


    def get_yu_talent_id
      if @user.yu_talent_uid.present?
        yu_talent_id = @user.yu_talent_uid
      else
        # check if user/candidate
        existing_candidate = @client.check_duplicates(@user.email)
        logger.info "--- existing_candidate = #{existing_candidate.data.map{ |c| c.id }.inspect}"
        if existing_candidate.record_count.to_i > 0
          logger.info '--- CANDIDATE RECORD FOUND'
          last_candidate = existing_candidate.data.last
          yu_talent_id = last_candidate.id
          @user.update(yu_talent_uid: yu_talent_id)
        else
          logger.info '--- CANDIDATE RECORD NOT FOUND'
          yu_talent_id = nil
        end
      end
    end


    def linkedin_description
      string = '<h1>Curriculum Vitae</h1>' +
        "<h2>#{@user.user_profile['first_name']} #{@user.user_profile['last_name']}</h2>"

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

      if @user.linkedin_profile['skills'].size > 0
        string = string + '<h3>SKILLS</h3>'
        @user.linkedin_profile['skills'].each do |skill|
          string = string + '<p>'
          skill_name = skill['skill'].present? ? 'Skill: ' + skill['skill'] + '<br />' : "Skill: N/A<br />"
          proficiency = skill['proficiency'].present? ? 'Proficiency: ' + skill['proficiency'] + '<br />' : "Proficiency: N/A<br />"
          years = skill['years'].present? ? 'Years: ' + skill['years'] + '<br />' : "Years: N/A<br />"

          string = string + skill_name + proficiency + years + '</p>'
        end
      end
      return string
    end



end
