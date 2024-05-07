# frozen_string_literal: true

# controller for the application
class ApplicationController < ActionController::API
  include Pundit
  before_action :authorized

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def encode_token(payload)
    jti = SecureRandom.uuid
    exp = 24.hours.from_now.to_i
    JWT.encode(payload.merge(exp: exp, jti: jti), Rails.application.credentials.secret_key_base, "HS256")
  end

  def decoded_token
    header = request.headers["Authorization"]
    return nil if header.nil?

    token = header.split.last if header
    begin
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true)[0]
      return nil if JwtDenylist.exists?(jti: decoded["jti"])

      decoded
    rescue JWT::DecodeError
      nil
    end
  end

  def current_user
    return nil unless decoded_token

    user_id = decoded_token["user_id"]
    @user = User.find_by(id: user_id)
  end

  def authorized
    render json: { message: "Please log in" }, status: :unauthorized unless current_user
  end

  private

  def user_not_authorized
    render json: { error: "No estas autorizado para realizar esta accion!" }, status: :forbidden
  end
end
