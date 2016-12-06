class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  http_basic_authenticate_with name: Rails.application.secrets.username, 
   							   password: Rails.application.secrets.password

  protect_from_forgery with: :null_session
  skip_before_action  :verify_authenticity_token
end
