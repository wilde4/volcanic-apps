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
        @response = send_request("CandidateDetails", @dup_attributes)
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