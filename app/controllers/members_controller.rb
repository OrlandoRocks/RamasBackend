# frozen_string_literal: true

# Handles the members of the application
class MembersController < ApplicationController
  def show
    authorize current_user, :profile?

    render json: current_user, serializer: UserSerializer, adapter: :json_api, meta: { token: decoded_token },
           status: :created
  end

  def residentials
    @residentials = policy_scope(Residential)
    authorize Residential

    render json: @residentials, each_serializer: ResidentialSerializer, adapter: :json_api, status: :ok
  end
end
