class RecruitiveController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  before_filter :set_key, only: [:index]

  def index
    @host = @key.host
    @settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    render layout: false
  end

  def activate_app
    key = Key.new
    key.host = Rails.env.development? ? "#{params[:data][:host]}:3000" : params[:data][:host]
    key.app_dataset_id = params[:data][:app_dataset_id]
    key.api_key = params[:data][:api_key]
    key.protocol = params[:data][:protocol]
    key.app_name = params[:controller]

    payload = { document_generator:
                {
                  name: "Recruitive XML",
                  response_format: "XML",
                  model: "Job",
                  repeating_node: "bar",
                  endpoint_type: "text",
                  endpoint: "<foo><bar><baz>foo</baz></bar></foo>",
                  active: true,
                  send_empty_nodes: true,
                  private: true
                },
                nodes:
                  [
                    {
                      name: "baz",
                      mapping: "job_title",
                      model: "Job",
                      node_cdata: true
                    }
                  ]
                }

    url = "#{key.protocol}#{key.host}/api/v1/document_generators.json?api_key=#{key.api_key}"
    response = HTTParty.post(url, { body: payload })

    if response.code == 200

      url = response['url']

      settings = AppSetting.find_by(dataset_id: params[:data][:app_dataset_id])

      if settings.present?
        settings.update(settings: { url: url })
      else
        settings = AppSetting.create(dataset_id: params[:data][:app_dataset_id], settings: { url: url })
      end

    end

    respond_to do |format|
      format.json { render json: { success: key.save }}
    end
  end
end
