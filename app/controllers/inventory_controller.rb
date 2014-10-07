class InventoryController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  before_action :set_inventory_item, only: [:get_inventory]
  before_action :set_key, only: [:index, :new, :post_purchase]

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
    @inv_objs = Inventory.object_types(@inventory.dataset_id)
  end

  def edit
    @inventory = Inventory.find(params[:data][:inv_id])
    @inv_objs = Inventory.object_types(@inventory.dataset_id)
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

  # GET /inventory/available
  # Get all available inventory for an Object Type:
  # Params:
  #   * type - Type of object to lookup (Job, Match, etc)
  def get_available
    if inv_obj
      @inventory = Inventory.by_object(inv_obj[:id]).select{|iv| iv.within_date}
    end

    respond_to do |format|
      format.json { render json: { success: true, items: @inventory || [] } }
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
  def post_purchase
    inventory_item = Inventory.find(params[:data][:inventory_id])

    # Work out the field to be edited, will be a record in future
    case inventory_item.object_type
    when "Credit"
      buy_credit(params)

    when "Job", "Premium Job"
      # charge a credit
      response = create_and_charge_credit(params, 1)
      if JSON.parse(response)["response"]["status"] == "success"
        # set the job as paid for:
        response = set_job_paid(params)
      end

    when "Job of the Week"
      response = set_job_paid(params)
      if JSON.parse(response)["response"]["status"] == "success"
        days_active = params[:data][:period].to_i
        job = FeaturedJob.find_by(job_id: params[:data][:job_id])

        job.feature_start = FeaturedJob.next_available_date(@key.app_dataset_id)
        job.feature_end = job.feature_start + days_active.days
        if job.save
          response = { success: true, message: "Successfully saved Job." }
        else
          response = { success: false, errors: job.errors }
        end
      end

    when "EG_Job_individual_employer", "EG_Job_employer"
      # UPDATE JOB paid: true
      job_likes = LikesJob.find_by(job_id: params[:data][:job_id])
      job_likes.update(paid: true) if job_likes

      response = { state: 'success' }
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
      value: credit_value 
    }
    post_to_api(resource_action, attribute_key, attributes)
  end

  # Performs logic to get a Job set as 'paid' via the API
  def set_job_paid(params)
    resource_action = "jobs/#{params[:data][:job_id]}/set_paid"
    attribute_key = :job
    attributes = {
      user_token: params[:data][:user_token],
      paid: true,
      expiry_date: 30.days.from_now
    }
    post_to_api(resource_action, attribute_key, attributes)
  end

  # Sends a post request to the API, on the path in resource_action
  # Data K/V is akin to "credit: credit_data_hash"
  def post_to_api(resource_action, attribute_key, attributes)
    endpoint_str = "http://#{@key.host}/api/v1/#{resource_action}.json"
    data = {
      api_key: @key.api_key,
      attribute_key => attributes # builds params[:<object_type>][:<data>]
    }
    # Make HTTParty go talk to the API:
    response = HTTParty.post(endpoint_str, { body: data })
    return response.body
  end

  def set_key
    @key = Key.find_by(host: params[:referrer])
    render nothing: true, status: 401 and return if @key.blank?
  end

  def inventory_params
    params.require(:inventory).permit(:id, :name, :start_date, :end_date, :price,
      :object_type, :dataset_id)
  end

  def set_inventory_item
    @inventory = Inventory.find(params[:id])
  end
end