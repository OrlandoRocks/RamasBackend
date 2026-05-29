# frozen_string_literal: true

# Public signup and super-user-only user management for the admin UI.
class UsersController < ApplicationController
  skip_before_action :authorized, only: [:signup]

  before_action :set_user, only: %i[show update destroy]

  # POST /signup — public client registration
  def signup
    client_role = Role.find_or_create_by!(name: "client")
    user = User.create!(signup_params.merge(role: client_role))
    token = encode_token(user_id: user.id)
    render json: user, serializer: UserSerializer, adapter: :json_api, meta: { token: token }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # GET /users
  def index
    @users = policy_scope(User).includes(:role, :client).order(:id)
    authorize User

    render json: @users,
           each_serializer: UserSerializer,
           adapter: :json_api,
           meta: { roles: assignable_roles }
  end

  # GET /users/:id
  def show
    authorize @user
    render json: @user, serializer: UserSerializer, adapter: :json_api, meta: { roles: assignable_roles }
  end

  # POST /users
  def create
    authorize User

    @user = User.new(management_params)
    if @user.save
      render json: @user.reload, serializer: UserSerializer, adapter: :json_api, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    authorize @user

    attrs = management_params
    attrs = attrs.except(:password) if attrs[:password].blank?

    if @user.update(attrs)
      sync_residential_assignments!(@user)
      render json: @user, serializer: UserSerializer, adapter: :json_api
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    authorize @user

    if @user.id == current_user.id
      return render json: { errors: ["You cannot delete your own account"] }, status: :unprocessable_entity
    end

    @user.destroy!
    render json: { message: "User was successfully destroyed." }, status: :ok
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  def signup_params
    params.require(:user).permit(:name, :last_name, :email, :password)
  end

  def management_params
    params.require(:user).permit(:name, :last_name, :email, :password, :role_id, :client_id, residential_ids: [])
  end

  def sync_residential_assignments!(user)
    ids = params.dig(:user, :residential_ids)
    return if ids.nil?
    return if user.client?

    user.residential_ids = ids.reject(&:blank?).map(&:to_i)
  end

  def assignable_roles
    Role.order(:name).map { |role| { id: role.id, name: role.name } }
  end
end
