# frozen_string_literal: true
class MembersController < ApplicationController
  before_action :authorized

  def index
    @users = User.all
    render json: @users, each_serializer: UserSerializer, adapter: :json_api, status: :ok
  end

  def show
    render json: current_user, serializer: UserSerializer, adapter: :json_api, meta: { token: decoded_token }, status: :created
  end
end
