class RecruiticsController < ApplicationController
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
                  repeating_node: "job",
                  endpoint_type: "text",
                  endpoint: sample_xml,
                  active: true,
                  send_empty_nodes: true,
                  private: true
                },
                nodes:
                  [
                    {
                      name: "publisher",
                      mapping: "name",
                      model: "Site",
                      node_cdata: false
                    },
                    {
                      name: "publisherurl",
                      mapping: "site_url",
                      model: "Site",
                      node_cdata: false
                    },
                    {
                      name: "lastbuilddate",
                      mapping: "current_time",
                      model: "Site",
                      node_cdata: false
                    },
                    {
                      name: "ref_id",
                      mapping: "job_reference",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "title",
                      mapping: "job_title",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "city",
                      mapping: "job_location",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "country",
                      mapping: "country",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "description",
                      mapping: "job_description",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "joburl",
                      mapping: "job_URL",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "categories",
                      mapping: "disciplines",
                      model: "Job",
                      node_cdata: false
                    },
                    {
                      name: "companyname",
                      mapping: "client_name",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "applyurl",
                      mapping: "job_apply_URL",
                      model: "Job",
                      node_cdata: true
                    },
                    {
                      name: "salary",
                      mapping: "salary_free",
                      model: "Job",
                      node_cdata: true
                    }
                  ]
                }

    url = "#{key.protocol}#{key.host}/api/v1/document_generators.json?api_key=#{key.api_key}"
    response = HTTParty.post(url, { body: payload })

    if response.code == 200

      settings = AppSetting.find_by(dataset_id: params[:data][:app_dataset_id])

      if settings.present?
        settings.update(settings: { url: response['url'], secure_random: response['secure_random'] })
      else
        settings = AppSetting.create(dataset_id: params[:data][:app_dataset_id], settings: { url: response['url'], secure_random: response['secure_random'] })
      end

    end

    respond_to do |format|
      format.json { render json: { success: key.save }}
    end
  end

  def deactivate_app
    key = Key.where(app_dataset_id: params[:data][:app_dataset_id], app_name: params[:controller]).first
    settings = AppSetting.find_by(dataset_id: params[:data][:app_dataset_id])
    
    url = "#{key.protocol}#{key.host}/api/v1/document_generators/#{settings.settings[:secure_random]}.json"
    response = HTTParty.delete(url)

    respond_to do |format|
      if key
        format.json { render json: { success: key.destroy }}
      else
        format.json { render json: { error: 'Key not found.' } }
      end
    end
  end

  private

  def sample_xml
    '<?xml version="1.0" encoding="UTF-8"?>
    <jobs>
    <publisher></publisher>
    <publisherurl></publisherurl>
    <lastbuilddate></lastbuilddate>
    <job>
    <ref_id></ref_id>
    <title></title> <city><![CDATA[Wilton]]></city>
    <state></state>
    <country></country>
    <description></description>
    <joburl></joburl>
    <categories></categories>
    <companyname></companyname>
    <applyurl></applyurl>
    <salary></salary>
    </job>
    </jobs>'
  end
end
