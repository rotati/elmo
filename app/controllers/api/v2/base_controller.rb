class API::V2::BaseController < ApplicationController
  skip_authorization_check  #for now at least

  rescue_from Exception, with: :handle_error

  before_action :authenticate

  serialization_scope :view_context

  protected

  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_or_request_with_http_token do |token, options|
      @api_user = User.find_by_api_key(token)
    end
  end

  protected

  def request_http_token_authentication(realm = "Application")
    self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
    render json: { errors: ["invalid_api_token"] }, status: :unauthorized
  end

  private

  def handle_error(exception, options = {})
    if exception.is_a?(ActiveRecord::RecordNotFound)
      render json: { errors: [exception.message.downcase.gsub(" ", "_")] }
    else
      raise exception
    end
  end
end
