module BondAdapt::SessionMethods
  extend ActiveSupport::Concern
  
  def session_id
    @session_id ||= bond_session_service.get_session_id 
  end

  def settings
    @settings ||= bond_session_service.settings
  end

  def bond_session_service
    @bond_session_service ||= BondAdapt::SessionService.new(dataset_id)
  end
end