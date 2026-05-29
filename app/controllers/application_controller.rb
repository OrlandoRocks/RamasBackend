# frozen_string_literal: true

# controller for the application
class ApplicationController < ActionController::API
  include Pundit::Authorization
  before_action :authorized

  after_action :verify_authorized, unless: :skip_verify_authorized?
  after_action :verify_policy_scoped, if: :verify_policy_scoped_for_action?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  POLICY_CLASSES = [ ClientPolicy, ContractPolicy, ExpensePolicy, LandPolicy, PaymentPolicy, ResidentialPolicy, UserPolicy ]

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
    return @current_user if defined?(@current_user)

    @current_user = nil
    return nil unless decoded_token

    user_id = decoded_token["user_id"]
    @current_user = User.find_by(id: user_id)
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

  def pundit_user
    current_user
  end

  private

  def skip_verify_authorized?
    (controller_path == "auth" && action_name == "login") ||
      (controller_path == "users" && action_name == "signup")
  end

  def verify_policy_scoped_for_action?
    return false if skip_verify_authorized?

    action_name == "index"
  end

  def user_not_authorized
    render json: { error: "No estas autorizado para realizar esta accion!" }, status: :forbidden
  end
end
