class InventoryController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  before_action :set_inventory_item, only: [:get_inventory]
  before_action :set_key, only: [:index, :edit, :new, :post_purchase]

  # GET /inventories/index
  # Outputs all Inventory Items in the system
  def index
    @items = Inventory.by_dataset(@key.app_dataset_id) || []

    respond_to do |format|
      format.html
      format.json { render json: {success: true, items: @items } }
    end
  end

  # Loads up the HTML form for use in the apps dashboard
  def new
    @inventory = Inventory.new
    @inventory.dataset_id = @key.app_dataset_id
    # @inv_objs = Inventory.object_types(@inventory.dataset_id)
    @inv_objs = Inventory.object_actions
  end

  def edit
    @inventory = Inventory.find(params[:data][:inv_id])
    # @inv_objs = Inventory.object_types(@inventory.dataset_id)
    @inv_objs = Inventory.object_actions
    credit_types_url = "http://#{@key.host}/api/v1/site.json"
    logger.info "--- credit_types_url = #{credit_types_url}"
    cr_response = HTTParty.get("http://#{@key.host}/api/v1/site.json", {})
    # logger.info "--- cr_response = #{cr_response.body.inspect}"
    response_json = JSON.parse(cr_response.body)
    @credit_types = response_json["credit_types"]
    logger.info "--- @credit_types = #{@credit_types.inspect}"
  end

   def update
    @inventory = Inventory.find(params[:inventory][:id])
    respond_to do |format|
      if @inventory.update(inventory_params)
        format.html { redirect_to action: 'index' }
        format.json { render json: { success: true, item: @inventory }}
      else
        format.html { render action: 'edit' }
        format.json { render json: {
          success: false, status: "Error: #{@inventory.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  # POST
  # Creates a new Inventory Item
  # Params:
  #   * name - Name of the new Inventory Item (Promotional Name?)
  #   * start_date - Date that the Inventory Item will be active
  #   * end_date - Date that ends the Inventory Item active period
  #   * price - Price to charge for this Inventory Item
  def create_item
    @inventory = Inventory.new(inventory_params)

    respond_to do |format|
      if @inventory.save
        @items = Inventory.all || []
        format.html { render action: 'index' }
        format.json { render json: { success: true, item: @inventory }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{@inventory.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  # GET /inventory(/:id)/inventory
  # Get an inventory by an Inventory ID
  def get_inventory
    respond_to do |format|
      format.json { render json: { success: true, item: @inventory } }
    end
  end

  # GET /inventories/available
  # Get all available inventory for an Object Type:
  # Params:
  #   * type - Type of object to lookup (Job, Match, etc)
  def get_available
    # if inv_obj
    #   @inventory = Inventory.by_object(inv_obj[:id]).select{|iv| iv.within_date}
    # end
    logger.info "--- params = #{params.inspect}"
    @inventory_items = Inventory.where(dataset_id: params[:data][:dataset]).select{|iv| iv.within_date}
    logger.info "--- @inventory_items = #{@inventory_items.inspect}"
    respond_to do |format|
      format.json { render json: { success: true, items: @inventory_items || [] } }
    end
  end

  # GET /inventory/best_price
  # Get the best price for an Inventory item
  # Params:
  #   * type - Type of object to lookup (Job, Match, etc)
  def cheapest_price
    @inventory = Inventory.by_object(params[:type])
                          .select{|iv| iv.within_date}
                          .sort_by{|i| i.price }
                          .first

    respond_to do |format|
      format.json { render json: { success: true, item: @inventory || [] } }
    end
  end

  # POST /inventory/post_purchase
  # An action that can be called on a purchased object
  # Params:
  #   * inventory_id - ID of the inventory object item purchased
  #   * purchased_id - The specific record ID that was purchased (Job(10), User(1442) etc.)
  #   * data - An array of data that will help the action comm. with the API
  # json: {"data"=>{"dataset_id"=>55, "inventory_id"=>"8", "user_id"=>42176, "job_id"=>35927}
  def post_purchase
    inventory_item = Inventory.find(params[:data][:inventory_id])

    # Work out the field to be edited, will be a record in future
    case inventory_item.object_action
    when 'Activate Job Listing for 7 days', 'Activate Job Listing for 30 days', 'Activate Featured Job Listing for 7 days', 'Activate Featured Job Listing for 30 days'
      days = 7 if inventory_item.object_action == 'Activate Job Listing for 7 days' or inventory_item.object_action == 'Activate Featured Job Listing for 7 days'
      days = 30 if inventory_item.object_action == 'Activate Job Listing for 30 days' or inventory_item.object_action == 'Activate Featured Job Listing for 30 days'
      hot = true if inventory_item.object_action == 'Activate Featured Job Listing for 7 days' or inventory_item.object_action == 'Activate Featured Job Listing for 30 days'
      hot = false if inventory_item.object_action == 'Activate Job Listing for 7 days' or inventory_item.object_action == 'Activate Job Listing for 30 days'

      if params[:data][:purchased_id].present?
        # HAVE JUST PAID THROUGH STRIPE
        response = create_and_charge_credit(params, 1)
      else
        # NEED TO DEDUCT A RELEVANT CREDIT
        response = charge_credit(params, 1, inventory_item.credit_type)
      end
      credit_charged = JSON.parse(response)["response"]["status"] == "success"
      response = credit_charged ? set_job_paid(params, days, hot) : { success: false }

    when 'Schedule as Job of the Week'
    when 'Mark Job Listing as paid'
    when 'Purchase credits'
    when 'Provide Candidate search for x days'
    when 'Provide CV Downloads for x days'
    when 'Deduct a credit'
    # when "Credit"
    #   buy_credit(params)

    # when "Job", "Premium Job"
    #   # charge a credit, or set if purc_via_credit
    #   if params[:data][:purchased_id].present?
    #     response = create_and_charge_credit(params, 1)
    #     credit_charged = JSON.parse(response)["response"]["status"] == "success"
    #   else
    #     credit_charged = true
    #   end

    #   if inventory_item.object_type == "Premium Job"
    #     params.require(:data).merge!({ hot: true })
    #   end
    #   # set the job as paid for:
    #   response = set_job_paid(params)
      
    # when "Job of the Week"
    #   response = set_job_paid(params)
    #   if JSON.parse(response)["response"]["status"] == "success"
    #     days_active = params[:data][:period].to_i
    #     job = FeaturedJob.find_by(job_id: params[:data][:job_id])

    #     job.feature_start = FeaturedJob.next_available_date(@key.app_dataset_id)
    #     job.feature_end = job.feature_start + days_active.days
    #     if job.save
    #       response = { success: true, message: "Successfully saved Job." }
    #     else
    #       response = { success: false, errors: job.errors }
    #     end
    #   end

    # when "EG_Job_individual_employer", "EG_Job_employer"
    #   # UPDATE JOB paid: true
    #   job_likes = LikesJob.find_by(job_id: params[:data][:job_id])
    #   job_likes.update(paid: true) if job_likes

    #   response = { state: 'success' }
    end

    respond_to do |format|
      format.json{ render json: response }
    end
  end

private

  # Create a credit, then immediately use it:
  def create_and_charge_credit(params, value)
    change_credit(params, -value) if change_credit(params, value)
  end

  def change_credit(params, credit_value)
    resource_action = "credits"
    attribute_key = :credit
    attributes = {
      user_token: params[:data][:user_token],
      payment_id: params[:data][:payment_id],
      value: credit_value,
      api_key: @key.api_key
    }
    post_to_api(resource_action, attribute_key, attributes)
  end

  def charge_credit(params, credit_value, credit_type)
    resource_action = "credits"
    attribute_key = :credit
    attributes = {
      user_token: params[:data][:user_token],
      value: credit_value,
      api_key: @key.api_key,
      credit_type: credit_type
    }
    post_to_api(resource_action, attribute_key, attributes)
  end

  # Performs logic to get a Job set as 'paid' via the API
  def set_job_paid(params, days, hot)
    resource_action = "jobs/#{params[:data][:job_id]}/set_paid"
    attribute_key = :job
    attributes = {
      user_token: params[:data][:user_token],
      paid: true,
      expiry_date: days.to_i.days.from_now,
      api_key: @key.api_key,
      hot: hot
    }
    post_to_api(resource_action, attribute_key, attributes)
  end

  # Sends a post request to the API, on the path in resource_action
  # Data K/V is akin to "credit: credit_data_hash"
  def post_to_api(resource_action, attribute_key, attributes)
    endpoint_str = "http://#{@key.host}/api/v1/#{resource_action}.json"
    data = {
      attribute_key => attributes # builds params[:<object_type>][:<data>]
    }
    # Make HTTParty go talk to the API:
    response = HTTParty.post(endpoint_str, { body: data })
    return response.body
  end

  def inventory_params
    params.require(:inventory).permit(:id, :name, :start_date, :end_date, :price,
      :object_action, :dataset_id, :credit_type)
  end

  def set_inventory_item
    @inventory = Inventory.find(params[:id])
  end
end