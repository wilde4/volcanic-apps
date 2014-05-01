class SkypeController < ApplicationController
  
  def consultant
    @skype_username = params[:skype_username] if params[:skype_username]
    respond_to do |format|
      format.html
    end
  end
  
end