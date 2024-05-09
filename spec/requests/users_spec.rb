# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users" do
  let(:role) { create(:role) }
  let(:user_params) do
    {
      user: {
        name: "John",
        last_name: "Doe",
        email: "john.doe@example.com",
        password: "password",
        role_id: role.id
      }
    }
  end

  describe "POST /users" do
    it "creates a new user and returns the user object with a token" do
      post '/signup', params: user_params
      expect(response).to have_http_status(:created)
      expect(json['data']['attributes']['email']).to eq(user_params[:user][:email])
      expect(json['meta']).to have_key('token')
    end

    context "when missing required parameters" do
      it "returns a bad request response" do
        post '/signup', params: { user: { name: "John", role_id: role.id } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to include("Password can't be blank", "Email can't be blank")
      end
    end
  end

  def json
    JSON.parse(response.body)
  end
end
