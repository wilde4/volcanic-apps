class Bullhorn::SendCategoryService < BaseService
  attr_reader :bullhorn_id, :category_id, :client
  private :bullhorn_id, :category_id, :client
  
  def initialize(bullhorn_id, client, category_id)
    @bullhorn_id = bullhorn_id
    @client = client
    @category_id = category_id
  end
  
  def send_category_to_bullhorn
     log_response(category_request)
  end
  
  private
  
    def category_request
      binding.pry
      client.create_candidate({}.to_json, { candidate_id: bullhorn_id, association: 'categories', association_ids: "#{category_id}" })
    end
    
    def log_response(response)
      Rails.logger.info "--- categories_response = #{response.inspect}" 
    end
end