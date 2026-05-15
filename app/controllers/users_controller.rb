# frozen_string_literal: true

# Handles the users of the application
class UsersController < ApplicationController
  before_action :set_user, only: %i[update]
  skip_before_action :authorized, only: [:create]

  def create
    user = User.create!(user_params)
    @token = encode_token(user_id: user.id)
    render json: user, serializer: UserSerializer, adapter: :json_api, meta: { token: @token }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def profile
    @user = User.find_by(id: params[:id])
    render json: @user, serializer: UserSerializer, adapter: :json_api, status: :ok
  end

  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private
  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :last_name, :email, :password, :role_id)
  end
end
