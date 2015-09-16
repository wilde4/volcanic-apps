class ExtraFormFieldsController < ApplicationController 
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  before_filter :set_key, only: [:index, :new, :edit, :job_form]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    @extra_form_fields = ExtraFormField.where(app_dataset_id: @key.app_dataset_id)

  end

  def new
    @extra_form_field = ExtraFormField.new
    @extra_form_field.app_dataset_id = @key.app_dataset_id
  end

  def create
    @extra_form_field = ExtraFormField.new(extra_form_field_params)

    respond_to do |format|
      if @extra_form_field.save
        format.html { render action: 'index' }
        format.json { render json: { success: true, extra_form_field: @extra_form_field }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{@extra_form_field.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  def edit
    @extra_form_field = ExtraFormField.find_by(app_dataset_id: @key.app_dataset_id, id: params[:data][:extra_form_field_id])
  end

  def update
    @extra_form_field = ExtraFormField.find_by(params[:extra_form_field][:id])

    respond_to do |format|
      if @extra_form_field.update_attributes(extra_form_field_params)
        format.html { render action: 'index' }
        format.json { render json: { success: true, extra_form_field: @extra_form_field }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{@extra_form_field.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  def destroy
  end

  def job_form
    @extra_form_fields = ExtraFormField.where(app_dataset_id: @key.app_dataset_id, form: "job")
    @job = JSON.parse(params[:data][:job])
    render :layout => false
  end

  protected
    def extra_form_field_params
      params.require(:extra_form_field).permit(:app_dataset_id,
                                        :form,
                                        :param_key,
                                        :label,
                                        :hint)
    end


end