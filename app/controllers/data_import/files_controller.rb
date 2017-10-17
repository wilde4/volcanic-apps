class DataImport::FilesController < ApplicationController
  require 'sidekiq/api'

  layout "data_import"
  before_action :authenticate_profile!
  before_action :set_profile
  before_action :check_creating, only: [:index, :creating]
  before_action :check_importing, only: [:index, :importing]
  before_action :check_updating, only: [:index, :updating]
  before_action :set_file, only: [:show, :edit, :update, :destroy, :import, :importing, :updating, :errors]

  IMPORT_WORKERS = %w(ImportUsersWorker ImportClientsWorker ImportJobsWorker ImportBlogsWorker)

  def index
    @files = current_profile.data_import_files
    flash.now[:info] = 'Currently parsing a file...' if @creating
    flash.now[:info] = 'Currently importing users...' if @importing
  end

  def new
    @file = DataImport::File.new model: params[:model]

    # if Rails.env.development? 
    #   endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/user_groups.json")
    # else
      endpoint_url = URI("http://" + current_profile.host + "/api/v1/user_groups.json")
    # end

    response = HTTParty.get(endpoint_url, {:headers => { 'Content-Type' => 'application/json' }})
    parsed_response = JSON.parse response.body

    @user_groups =  parsed_response.map { |user_group| [user_group['name'], user_group['id']] }
  end

  def create
    if params[:data_import_file] && params[:data_import_file][:file]
      uploaded_io = params[:data_import_file][:file]
      params[:data_import_file][:filename] = params[:data_import_file][:file].original_filename
      params[:data_import_file].delete :file
      @xml_nodes = params[:data_import_file][:nodes].gsub("\r", "").split("\n") if params[:data_import_file][:nodes].present?

      file = Tempfile.new(params[:data_import_file][:filename], Rails.root.join('tmp'))
      file.write(uploaded_io.read.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
      file.close
      uploaded_io.rewind

      @file = current_profile.data_import_files.create(data_import_file_params)
      if @file.save
        if @file.create_headers(uploaded_io, @xml_nodes)
          CreateLinesWorker.perform_async(current_profile.id, @file.id, file.path)
          redirect_to creating_data_import_files_path(creating: true)
        else
          flash.now[:alert] = @file.errors.full_messages.join('. ')
          @file.destroy
          @file = DataImport::File.new model: params[:data_import_file][:model]
          render :new
        end
      else
        flash.now[:alert] = @file.errors.full_messages.join('. ')
        render :new
      end
    else
      @file = DataImport::File.new model: params[:data_import_file][:model]
      flash.now[:alert] = 'Please select a file'
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if params[:data_import_file].present?
      if params[:data_import_file][:file]
        uploaded_io = params[:data_import_file][:file]
        params[:data_import_file][:filename] = params[:data_import_file][:file].original_filename
        params[:data_import_file].delete :file

        file = Tempfile.new(params[:data_import_file][:filename], Rails.root.join('tmp'))
        file.write(uploaded_io.read.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
        file.close
        uploaded_io.rewind

        if @file.filetype == 'csv'
          if @file.check_headers(uploaded_io)
            UpdateLinesWorker.perform_async(current_profile.id, @file.id, file.path)
            redirect_to updating_data_import_file_path(@file, updating: true)
          else
            redirect_to data_import_file_path(@file), alert: "Headers of update file don't match original file headers"
          end
        else
          UpdateLinesWorker.perform_async(current_profile.id, @file.id, file.path)
          redirect_to updating_data_import_file_path(@file, updating: true)
        end
      else
        if params[:data_import_file][:headers_attributes]
          params[:data_import_file][:headers_attributes].each do |k,v|
            if v[:registration_question_id] == 'created_at'
              params[:data_import_file][:created_at_mapping] = @file.headers.find(v[:id]).name
              params[:data_import_file][:headers_attributes][k][:registration_question_id] = nil
            elsif v[:registration_question_id] == 'full_name'
              # params[:data_import_file][:created_at_mapping] = @file.headers.find(v[:id]).name
              params[:data_import_file][:headers_attributes][k][:registration_question_id] = nil
            end
          end
        end
        @file.update(data_import_file_params)
        redirect_to data_import_file_path(@file)
      end
    end
  end

  def destroy
    @file.destroy
    redirect_to data_import_files_path, notice: 'File deleted'
  end

  def creating
    unless @creating
      redirect_to data_import_files_path
    end
  end

  def importing
    unless @importing
      redirect_to data_import_file_path(@file)
    end
    @jobs = Sidekiq::ScheduledSet.new.select { |j| j.args.first == current_profile.id && IMPORT_WORKERS.include?(j.klass) }.count + Sidekiq::Queue.new.select { |j| j.args.first == current_profile.id && IMPORT_WORKERS.include?(j.klass) }.count
  end

  def updating
    unless @updating
      redirect_to data_import_file_path(@file)
    end
  end

  def import
    case @file.model
    when 'client'
      # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/key_locations.json")
      endpoint_url = URI("http://" + current_profile.host + "/api/v1/key_locations.json")

      response = HTTParty.get(endpoint_url, {:headers => { 'Content-Type' => 'application/json' }})
      parsed_response = JSON.parse response.body

      @key_locations = {}
      parsed_response.each { |l| @key_locations[l["name"]] = l["reference"] }

    when 'job'
      # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/clients/search.json?api_key=#{current_profile.api_key}")
      endpoint_url = URI("http://" + current_profile.host + "/api/v1/clients/search.json?api_key=#{current_profile.api_key}")

      response = HTTParty.get(endpoint_url, {:headers => { 'Content-Type' => 'application/json' }})
      parsed_response = JSON.parse response.body

      # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/clients/search.json?api_key=#{current_profile.api_key}&per_page=#{parsed_response["total_count"]}")
      endpoint_url = URI("http://" + current_profile.host + "/api/v1/clients/search.json?api_key=#{current_profile.api_key}&per_page=#{parsed_response["total_count"]}")
      
      response = HTTParty.get(endpoint_url, {:headers => { 'Content-Type' => 'application/json' }})
      parsed_response = JSON.parse response.body

      @client_tokens = {}
      parsed_response["clients"].each { |c| @client_tokens[c["name"]] = c["client_token"] }

    when 'user'
      # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/clients/search.json?api_key=#{current_profile.api_key}")
      endpoint_url = URI("http://" + current_profile.host + "/api/v1/clients/search.json?api_key=#{current_profile.api_key}")

      response = HTTParty.get(endpoint_url, {:headers => { 'Content-Type' => 'application/json' }})
      parsed_response = JSON.parse response.body

      # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/clients/search.json?api_key=#{current_profile.api_key}&per_page=#{parsed_response["total_count"]}")
      endpoint_url = URI("http://" + current_profile.host + "/api/v1/clients/search.json?api_key=#{current_profile.api_key}&per_page=#{parsed_response["total_count"]}")
      
      response = HTTParty.get(endpoint_url, {:headers => { 'Content-Type' => 'application/json' }})
      parsed_response = JSON.parse response.body

      @client_ids = {}
      parsed_response["clients"].each { |c| @client_ids[c["name"]] = c["id"] }
    end
    seconds_delay = 0
    @file.lines.where(processed: false).in_groups_of(@file.max_size || 5) do |group|
      send_time = Time.zone.now + seconds_delay.seconds
      group.each do |line|
        # Group can return nils as padding
        if line.present?
          puts "ID: #{line.id}"
          puts "delay: #{seconds_delay}"
          case @file.model
          when 'user'
            ImportUsersWorker.perform_at(send_time, current_profile.id, line.id, @client_ids[line.values['company_name']])
          when 'client'
            key_locations = line.values['key_locations'].split(',').map { |name| @key_locations[name] }.compact.join(',') rescue nil
            ImportClientsWorker.perform_at(send_time, current_profile.id, line.id, key_locations)
          when 'job'
            ImportJobsWorker.perform_at(send_time, current_profile.id, line.id, @client_tokens[line.values['company_name']])
          when 'blog'
            ImportBlogsWorker.perform_at(send_time, current_profile.id, line.id)
          end
        end
      end
      seconds_delay += @file.delay_interval || 1
    end
    redirect_to importing_data_import_file_path(@file, importing: true)
  end

  def errors
    @error_lines = @file.lines.errors
  end

  private

  def data_import_file_params
    params.require(:data_import_file).permit(:filename, :user_group_id, :user_id, :post_mapping, :uid, :created_at_mapping, :max_size, :delay_interval, :model, headers_attributes: [ :id, :registration_question_id, :multiple_answers, :column_name, :nl2br ])
  end

  def check_creating
    if params[:creating] || sidekiq_worker_present?(%w(CreateLinesWorker))
      @creating = true
      flash.now[:info] = 'Parsing file...'
    end
  end

  def check_importing
    if params[:importing] || sidekiq_worker_present?(IMPORT_WORKERS)
      @importing = true
      flash.now[:info] = 'Importing...'
    end
  end

  def check_updating
    if params[:updating] || sidekiq_worker_present?(%w(UpdateLinesWorker))
      @updating = true
      flash.now[:info] = 'Updating file...'
    end
  end

  def set_file
    @file = current_profile.data_import_files.find params[:id]
  end

  def sidekiq_worker_present?(workers)
    Sidekiq::Workers.new.select { |process_id, thread_id, work| work['payload']['args'][0] == current_profile.id && workers.include?(work['payload']['class']) }.present? ||
    Sidekiq::ScheduledSet.new.select { |j| j.args.first == current_profile.id && workers.include?(j.klass) }.present?
  end

end