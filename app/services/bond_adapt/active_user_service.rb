class BondAdapt::ActiveUserService < BaseService
  include VolcanicApiMethods
  attr_reader :dataset_id, :app_name
  private :dataset_id, :app_name
  
  def initialize(dataset_id)
    @dataset_id = dataset_id
    @app_name = 'bond_adapt'
  end
  
  def send_activity_logs_for_active_user
    active_users_arr.each do |user_array|
      BondAdapt::ActivityService.new({user_email: user_array[0], user_name: user_array[1], user_id: user_array[2], dataset_id: dataset_id }).send_activity_log
    end
  end
  
  private
  
    def active_users_responce_body(page)
      HTTParty.get(end_point('active_users') << "&page=#{page}" ).body
    end
  
    def end_point(end_point_name)
      "#{api_address}#{end_point_name}.json?"
    end
  
    def active_users_arr
      arr = []
      json_first_page = parse_body(active_users_responce_body("1"))
      if check_json?(json_first_page, 1) && pagination_is_there?(json_first_page)
        page_count(json_first_page).times do |index|
          json = parse_body(active_users_responce_body(page_number(index)))
          arr.concat(get_user_details(json)) unless get_user_details(json) == nil
        end
      end
      arr  
    end
  
    def get_user_details(json)
      arr_2 =[]
      if check_json?(json, 0)
        json[0].each do |user|
          arr_2 << [user['email'], user['name'], user['id']]
        end
        arr_2
      else
        nil
      end
    end
  
end