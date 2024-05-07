#
class UsersController < ApplicationController
  skip_before_action :authorized, only: [:create]

  def create
    user = User.create!(user_params)
    @token = encode_token(user_id: user.id)
    render json: user, serializer: UserSerializer, adapter: :json_api, meta: { token: @token }, status: :created
  end

  private

  def user_params
    params.require(:user).permit(:name, :last_name, :email, :password, :role_id)
  end
end
