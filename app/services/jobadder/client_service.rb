class Jobadder::ClientService < BaseService

  def initialize(jobadder_setting)
    @jobadder_setting = jobadder_setting
    # setup_client
    @key = Key.find_by(app_dataset_id: jobadder_setting.dataset_id, app_name: 'jobadder')
  end

  def get_jobs

    response = HTTParty.get('https://api.jobadder.com/v2/jobs',
                            :headers => {"Authorization" => "Bearer "+ @jobadder_setting.ja_client_id,
                                          "Content-type" => "application/json"})
    puts response

  end

  # def setup_client
  #
  # end
end