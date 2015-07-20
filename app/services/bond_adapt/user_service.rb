class BondAdapt::UserService < BaseService

  def initialize(user)
    @user         = user
    if @user.user_data['user_group_name'].present?
      @user_group_name    = @user.user_data['user_group_name']
    else
      @user_group_name    = @user.user_data['user_type']
    end
    @dataset_id   = @user.user_data['dataset_id']
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
      client = BondAdapt::ClientService.new(@dataset_id)

      if @user.bond_adapt_uid.present?
        bond_adapt_id = @user.bond_adapt_uid
      else
        @dup_attributes = Hash.new
        @dup_attributes[:email] = @user.email
        # Rails.logger.info "--- @dup_attributes: #{@dup_attributes.inspect}"

        @response = client.find_user(@user.email)
        # Rails.logger.info "--- @response: #{@response.inspect}"
        if @response["count"] > 0
          Rails.logger.info '--- bond_adapt DUPLICATE CANDIDATE RECORD FOUND'
          @last_candidate = @response["records"].last
          # Rails.logger.info "--- @last_candidate: #{@last_candidate.inspect}"
          bond_adapt_id     = @last_candidate["candidateID"]
        else
          bond_adapt_id = nil
        end
      end
      return bond_adapt_id
    rescue => e
      Rails.logger.info "--- bond_adapt check_duplicates exception ----- : #{e.message}"
    end
  end

end