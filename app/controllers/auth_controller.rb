# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authorized, only: [:login]

  def login
    p "login_params: #{login_params}"
    @user = User.find_by(email: login_params[:email])
    if @user&.authenticate(login_params[:password])
      @token = encode_token({ user_id: @user.id })
      render json: @user, serializer: UserSerializer, adapter: :json_api, meta: { token: @token }, status: :accepted
    else
      render json: { message: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def logout
    jwt_token = decoded_token
    p "jwt_token: #{jwt_token}"
    JwtDenylist.create(jti: jwt_token['jti'], exp: Time.at(jwt_token['exp']))

    render json: { message: "Logout successful" }, status: :ok
  end

  private

  def login_params
    params.require(:auth).permit(:email, :password)
  end
end
