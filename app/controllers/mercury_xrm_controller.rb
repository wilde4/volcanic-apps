class MercuryXrmController < ApplicationController

  layout "no_jquery_application"

  def mercury_xrm_dashboard
    @encrypted_email = encrypt_email(params[:data][:email])
    @encrypted_email.gsub!("\n", '\n')
    render "mercury_xrm_dashboard"
  end

  private

  def encrypt_email(email)
    return "" if email.blank?
    return AesEncryptionService.encrypt_email(email)
  end

  # user dashboard, checks to see if the Mercury XRM App is enabled
  # if yes: then calls the insert_hooks helper
  # which constructs a HTTP GET request to Volcanic Apps server, passing the current_users email
  # once VA receives this request: then it performs some logic
  # and renders/returns a view which is then displayed on the user dashboard
end
