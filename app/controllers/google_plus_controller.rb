class GooglePlusController < ApplicationController

  def author
    @user = JSON.parse(params[:user]) if params[:user]

    respond_to do |format|
      format.html
    end
  end
  
end