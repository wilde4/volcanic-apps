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
    if @key
      @inventory = Inventory.new
      @inventory.dataset_id = @key.app_dataset_id
      @inv_objs = Inventory.object_types(@inventory.dataset_id)
    else
      redirect_to action: 'index'
    end
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
  #   * data - A splat of data that will help the action comm. with the API
  def post_purchase
    if @key # if it's from an authenticated host
      inventory_item = Inventory.find(params[:data][:inventory_id])

      # Work out the field to be edited, will be a record in future
      case inventory_item.object_type
      when "Credit"
        http_method = :post
        resource_action = "credits"
        attribute_key = :credit
        attributes = { user_token: params[:data][:user_token], value: 1 }

      when "Job", "Premium Job", "Job of the Week"
        # Generate a credit for the job:
        req_data = {
          api_key: @key.api_key,
          credit: { user_token: params[:data][:user_token], value: 1 }
        }
        #credit_response = HTTParty.post("http://#{@key.host}:3000/api/v1/credits.json", { body: req_data })

        # Setup a call to /jobs to set a job as paid
        http_method = :post
        resource_action = "jobs/#{params[:data][:job_id]}/set_paid"
        attribute_key = :job
        attributes = { user_token: params[:data][:user_token], paid: true, expiry_date: 30.days.from_now }

      when "EG_Job_individual_employer", "EG_Job_employer"
        # UPDATE JOB paid: true
        job_likes = LikesJob.find_by(job_id: params[:data][:job_id])
        job_likes.update(paid: true) if job_likes

        response = {state: 'success'}
        respond_to do |format|
          format.json{ render json: response }
        end
        return
      end

      # Build the endpoint to talk to, and the query params in request_data
      endpoint_str = "http://#{@key.host}:3000/api/v1/#{resource_action}.json"
      request_data = {
        api_key: @key.api_key,
        attribute_key => attributes # builds params[:<object_type>][:<data>]
      }

      # Make HTTParty go talk to the API:
      response = HTTParty.send(http_method, endpoint_str, { body: request_data })
      respond_to do |format|
        format.json{ render json: response.body }
      end
    end
  end

private

  def set_key
    @key = Key.find_by(host: params[:referrer])
  end

  def inventory_params
    params.require(:inventory).permit(:id, :name, :start_date, :end_date, :price,
      :object_type, :dataset_id)
  end

  def set_inventory_item
    @inventory = Inventory.find(params[:id])
  end
end