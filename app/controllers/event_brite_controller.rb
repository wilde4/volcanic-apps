class EventBriteController < ApplicationController
  
  def related_events
    @job = JSON.parse(params[:job]) if params[:job]
    @settings = JSON.parse(params[:settings]) if params[:settings]
    respond_to do |format|
      format.html
    end
  end


end