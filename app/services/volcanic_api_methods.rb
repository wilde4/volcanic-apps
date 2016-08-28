module VolcanicApiMethods
  extend ActiveSupport::Concern
  
  def page_number(index)
    (index + 1).to_s
  end

  def pagination_is_there?(json)
    json.present? && json[1].present? && json[1][0].present? && json[1][0].is_a?(Hash) && json[1][0]['pagination'].present? && page_count(json).present?
  end

  def page_count(json)
    json[1][0]['pagination']['page_count'].to_i
  end

  def parse_body(body)
    JSON.parse(body)
  end

  def check_json?(json, slot)
    json.present? && json.is_a?(Array) && json[slot].present? && json[slot].is_a?(Array)
  end

  def key
    @key ||= Key.where(app_dataset_id: dataset_id, app_name: app_name).first
  end

  def api_address
    @api_address ||= "http://#{key.host}/api/v1/"
  end
end