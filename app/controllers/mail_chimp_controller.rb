class MailChimpController < ApplicationController
  protect_from_forgery with: :null_session
  before_filter :set_key, only: [:index, :callback, :new_condition]
  after_filter :setup_access_control_origin
  
  def index
    set_index_variables
    
    render layout: false
  end
  
  def callback
    host = key_host(@key)
    
    @attributes                       = Hash.new
    @attributes[:dataset_id]          = params[:data][:dataset_id]
    @attributes[:authorization_code]  = params[:data][:code]
    @attributes[:access_token]        = MailChimp::AuthenticationService.get_access_token(
                                          params[:data][:id],
                                          host,
                                          params[:data][:code])
                                          
    unless !@attributes[:access_token].present?
      @settings = MailChimpAppSettings.find_by(dataset_id: @attributes[:dataset_id])
      if @settings.present?
        if @settings.update(@attributes)
          flash[:notice]  = "App successfully authorised."
        else
          flash[:alert]   = "App could not be authorised."
        end
      else
        @settings = MailChimpAppSettings.new(@attributes)
        @settings.importing_users = false;
        if @settings.save
          flash[:notice]  = "App successfully authorised."
        else
          flash[:alert]   = "App could not be authorised."
        end
      end
    end
     
    set_index_variables
    render :index, layout: false

  end
  
  def new_condition
    @mail_chimp_app_settings = MailChimpAppSettings.find_by(dataset_id: @key.app_dataset_id)
    @mail_chimp_condition = MailChimpCondition.new
    
    host = key_host(@key)
    @user_groups_url = host + '/api/v1/user_groups.json'
    # @user_groups_url = 'http://meridian.dev.volcanic.co/api/v1/user_groups.json'
    
    @user_groups = HTTParty.get(@user_groups_url)
    @user_group_collection = []
    @registration_questions = [['Default (no conditions to match)','','']]
    @user_groups.each do |g|
      @user_group_collection << [g['name'],g['id']]
      if g['registration_question_groups'].present?
        g['registration_question_groups'].each do |registration_group|
          registration_group['registration_questions'].each do |question|
            @registration_questions << [question['label'],question['id'], g['id']]
          end
        end
      end 
    end
    
    gibbon = set_gibbon(@mail_chimp_app_settings.access_token)
    
    mailchimp_lists = gibbon.lists.retrieve
    @mailchimp_lists_collection = []
    mailchimp_lists['lists'].each do |list|
      @mailchimp_lists_collection << [list['name'], list['id']]
    end
    
    @index_url = create_url(params[:data][:id], host, 'index')
    
    render layout: false
  end
  
  def save_condition
    condition_attributes = Hash.new
    condition_attributes[:mail_chimp_app_settings_id]    = params[:mail_chimp_condition][:mail_chimp_app_settings_id]
    condition_attributes[:user_group]                    = params[:mail_chimp_condition][:user_group]
    condition_attributes[:mail_chimp_list_id]            = params[:mail_chimp_condition][:mail_chimp_list_id]
    condition_attributes[:registration_question_id]      = params[:mail_chimp_condition][:registration_question_id]
    condition_attributes[:answer]                        = params[:mail_chimp_condition][:answer]
    
    @mailchimp_condition = MailChimpCondition.new(condition_attributes)
    @key = Key.find(params[:key_id])
    host = key_host(@key)
    index_url = create_url(params[:app_id], host, 'index')
    
    if @mailchimp_condition.save
      flash[:notice]  = "Condition succesfully created"
      redirect_to index_url
    else
      render json: { success: false, status: "Error: #{@mailchimp_condition.errors.full_messages.join(', ')}" }
    end
    
  end
  
  def delete_condition
    @condition = MailChimpCondition.find(params[:id])
    
    @key = Key.find(params[:key_id])
    host = key_host(@key)
    index_url = create_url(params[:app_id], host, 'index')
    
    if @condition.destroy
      redirect_to index_url, notice: 'Project deleted correctly'
    else
      flash[:alert] = "<ul>" + @project.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>"
    end
  end
  
  def classify_user
    # logger.info "--- classify_user, params = #{params.inspect}"
    answers = {}
    if params[:registration_answer_hash_id].present?
      answers = params[:registration_answer_hash_id]
    end
    # logger.info "--- answers = #{answers.inspect}"
    operations = check_user_conditions(answers,params[:user],params[:user_profile], params[:user]['dataset_id'])
    # logger.info "--- operations = #{operations.inspect}"
    send_batch(operations,params[:user]['dataset_id'])

    head :ok, content_type: 'text/html'
  end
  
  def import_user_group
    @key = Key.find(params[:key_id])
    @host = key_host(@key)
    index_url = create_url(params[:app_id], @host, 'index')
    
    settings = MailChimpAppSettings.find_by(dataset_id: params[:dataset_id])
    settings.importing_users = true
    settings.save
    
    Thread.new do
      users_url = Rails.env.development? ? "#{@host}/api/v1/users/#{params[:user_group_id]}/user_group_users.json?api_key=#{@key.api_key}" : "http://#{host}/api/v1/users/#{params[:user_group_id]}/user_group_users.json?api_key=#{@key.api_key}"
    
      users_per_page = 500
      i = 1 #ask api first page
      available_users = true

      while available_users  do
        puts("Inside the loop page = #{i}" )
        # logger.info "--- Inside the loop page = #{i}"
        users_url = users_url + "&per_page=#{users_per_page}&page=#{i}"
        # logger.info "--- users_url = #{users_url}"
        begin
          @users = HTTParty.get(users_url)
          users_array = []
          if @users['users'].size != 0
            @users['users'].each do |u|
              # logger.info "--- u = #{u.inspect}"
              if u['user_group_id'].to_i == params[:user_group_id].to_i
                user_hash = {
                  user: {
                    'email' => u['email'],
                    'user_group_id' => u['user_group_id']
                  },
                  user_profile:{
                    'first_name' => u['first_name'],
                    'last_name' => u['last_name']
                  },
                  registration_answer_hash_id: u['registration_answers_id'],
                  dataset_id: u['dataset_id']
                }
                users_array << user_hash
              end
            end
            # logger.info "--- users_array = #{users_array.inspect}"
            classify_user_group(users_array)
            i += 1
          else
            available_users = false
            settings.importing_users = false
            settings.save
          end
        rescue HTTParty::Error
          # don´t do anything / whatever
          logger.info "--- HTTParty::Error"
          available_users = false
          settings.importing_users = false
          settings.save
        rescue StandardError => e
          logger.info "--- Error = #{e.inspect}"
          # rescue instances of StandardError,
          # i.e. Timeout::Error, SocketError etc
          available_users = false
          settings.importing_users = false
          settings.save
        end    
       
      end
      ActiveRecord::Base.connection_pool.release_connection
    end
    redirect_to index_url
  end
  
  
  private
  
    def set_index_variables

      @app_id = params[:data][:id]
      host = key_host(@key)
      @new_condition_url = create_url(@app_id, host, 'new_condition')
      @auth_url = MailChimp::AuthenticationService.client_auth(@app_id, host)
    
      @settings = MailChimpAppSettings.find_by(dataset_id: params[:data][:dataset_id])
    
      @mailchimp_conditions = @settings.mail_chimp_conditions if @settings.present?
    
      if @settings.present? && @settings.access_token.present? 
        
        @user_groups_url = host + '/api/v1/user_groups.json'
        # @user_groups_url = 'http://meridian.dev.volcanic.co/api/v1/user_groups.json'
        @user_groups = HTTParty.get(@user_groups_url)
        @import_group_url = Rails.env.development? ? 'http://localhost:3001/mail_chimp/import_user_group' : 'https://apps.volcanic.co/mail_chimp/import_user_group'
        gibbon = set_gibbon(@settings.access_token)
    
        @mailchimp_lists = gibbon.lists.retrieve
        @mailchimp_lists_collection = []
        @mailchimp_lists['lists'].each do |list|
          @mailchimp_lists_collection << [list['name'], list['id']]
        end
      end
    end
    
    def create_url(app_id, host, endpoint)
      "#{host}/admin/apps/#{app_id}/#{endpoint}"
    end
    
    
    def key_host(key)
      url_aux = key.host
      url_aux = URI.parse(url_aux)

      return url_aux if url_aux.scheme
      return "#{@key.protocol}#{url_aux}:3000" if Rails.env.development?
      "#{@key.protocol}#{url_aux}"
      
    end
    
    def set_gibbon(access_token)
      response = HTTParty.get(
        "https://login.mailchimp.com/oauth2/metadata",
        headers: {"Authorization" => "OAuth #{access_token}"}
      )
      gibbon = Gibbon::Request.new
      gibbon.api_endpoint = response['api_endpoint']
      gibbon.api_key = access_token
      gibbon
    end
    
    def compare_answers(answer_one, answer_two)
      match = false
      two = answer_two.downcase
      
      if answer_one.kind_of?(Array)
        answer_one.each do |option|
          one = option.downcase
          if one == two
            match = true
          else
            if (one.include? two) || (two.include? one)
              match = true
            end
          end
        end
      else
        one = answer_one.downcase
        if one == two
          match = true
        else
          if (one.include? two) || (two.include? one)
            match = true
          end
        end
      end
      
      match
    end
    
    def upsert_user(email, first_name, last_name, mailchimp_list_id, dataset_id)
      settings = MailChimpAppSettings.find_by(dataset_id: dataset_id)
      gibbon = set_gibbon(settings.access_token)
      
      md5_email = Digest::MD5.hexdigest(email.downcase)
      begin
       gibbon.lists(mailchimp_list_id).members(md5_email).upsert(body: {email_address: email, status: "subscribed",merge_fields: {FNAME: first_name, LNAME: last_name}})
      rescue Gibbon::MailChimpError => e
       puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
      end
      puts "USER SENT to: #{mailchimp_list_id}"
    end
    
    def send_batch(batch_operations, dataset_id)
      # logger.info "--- send_batch"
      puts batch_operations
      settings = MailChimpAppSettings.find_by(dataset_id: dataset_id)
      gibbon = set_gibbon(settings.access_token)
      begin
        gibbon.batches.create(body: {operations: batch_operations})
      rescue Gibbon::MailChimpError => e
       puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
      end
      puts "BATCH SENT"
    end
    
    def create_batch_operation_json(email, first_name, last_name, list_id)
      batch_operation = {
                          method: "POST",
                          path: "/lists/#{list_id}/members",
                          body: {
                              email_address: email,
                              status: "subscribed",
                              merge_fields: {FNAME: first_name, LNAME: last_name}
                          }.to_json
                      }
      batch_operation
    end
    
    def check_user_conditions(user_answers, user, user_profile, dataset_id)
      # logger.info "--- check_user_conditions, user = #{user.inspect}"
      operations = []
      operation_json = ''

      user_email = user['email']
      first_name = user_profile['first_name']
      last_name = user_profile['last_name']
    
      settings = MailChimpAppSettings.find_by(dataset_id: dataset_id)
      # logger.info "--- settings = #{settings.inspect}"
      mailchimp_ug_conditions = settings.mail_chimp_conditions.where(user_group: user['user_group_id'])
      # logger.info "--- mailchimp_ug_conditions = #{mailchimp_ug_conditions.inspect}"
      
      if mailchimp_ug_conditions.present?
        # logger.info "--- mailchimp_ug_conditions.present?"
        mailchimp_ug_conditions.each do |condition|
          # logger.info "--- condition = #{condition.inspect}"
          if condition.registration_question_id.blank?
            # logger.info "--- Default list"
            operation_json = create_batch_operation_json(user_email, first_name, last_name, condition.mail_chimp_list_id)
            operations.append(operation_json)
          end
          if user_answers.present?
            # logger.info "--- user_answers.present?"
            user_answers.each do |answer|
              # logger.info "--- answer = #{answer.inspect}"
              if answer[0].to_i == condition.registration_question_id
                if compare_answers(answer[1], condition.answer)
                  # logger.info "--- MATCH: #{answer[1]} - #{condition.answer}"
                  operation_json = create_batch_operation_json(user_email, first_name, last_name, condition.mail_chimp_list_id)
                  operations.append(operation_json)
                end
              end
            end
          end
        end
      end
      return operations
    end
    
    def classify_user_group(users_array = nil)
      # logger.info "--- classify_user_group, users_array = #{users_array.inspect}"
      if users_array.present?
        batch_operations = []
        dataset_id = users_array.first[:dataset_id]
        users_array.each do |u|
          answers = {}
          if u[:registration_answer_hash_id].present?
            answers = u[:registration_answer_hash_id]
          end
          operations = check_user_conditions(answers,u[:user],u[:user_profile], dataset_id)
          operations.each do |op|
            batch_operations.append(op)
          end
        end
        # logger.info "--- batch_operations = #{batch_operations.inspect}"
        send_batch(batch_operations, dataset_id)
      end
    end
  
end






