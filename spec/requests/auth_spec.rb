# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth" do
  let(:user) { create(:user, role: create(:role)) }
  let(:invalid_credentials) { { auth: { email: user.email, password: "wrong password" } } }

  describe "POST /login" do

    context "with invalid credentials" do
      it "returns an unauthorized response" do
        post "/login", params: invalid_credentials
        expect(response).to have_http_status(:unauthorized)
        expect(json["message"]).to eq("Invalid email or password")
      end
    end
  end

  describe "POST /logout" do
    context "when the user is logged in" do
      before do
        sign_in(user)
      end

      it "returns a success response and creates a denylist entry" do
        post "/logout", headers: @headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Logout successful")
        expect(JwtDenylist.count).to eq(1)
      end
    end

    context "when the user is not logged in" do
      it "returns a unauthorized response" do
        post "/logout", headers: @headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  def json
    JSON.parse(response.body)
  end
end
