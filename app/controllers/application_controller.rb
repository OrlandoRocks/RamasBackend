# frozen_string_literal: true

# controller for the application
class ApplicationController < ActionController::API
  include Pundit::Authorization
  before_action :authorized

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  POLICY_CLASSES = [ ClientPolicy, ContractPolicy, ExpensePolicy, LandPolicy, PaymentPolicy, ResidentialPolicy ]

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
    return @user if @user

    return nil unless decoded_token

    user_id = decoded_token["user_id"]
    @user = User.find_by(id: user_id)
  end

  def permissions(user)
    policies = {}

    POLICY_CLASSES.each do |policy_class|
      model_name = policy_class.model_name
      policies[model_name.to_s.underscore] = {}

      # Check each action defined in the policy
      policy_class.instance_methods(false).each do |action|
        next unless action.to_s.end_with?('?') # Filter only methods that end with '?'

        # Create an instance of the policy for the user and the model
        policy_instance = policy_class.new(user, model_name)

        # Store the permission result
        policies[model_name.to_s.underscore][action.to_s.chomp('?')] = policy_instance.send(action)
      end
    end

    policies
  end

  def authorized
    render json: { message: "Please log in" }, status: :unauthorized unless current_user
  end

  private

  def user_not_authorized
    render json: { error: "No estas autorizado para realizar esta accion!" }, status: :forbidden
  end
end
