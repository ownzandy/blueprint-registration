module AuthHelper

  def credentials
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(Rails.application.secrets.username, Rails.application.secrets.password)
  end

end