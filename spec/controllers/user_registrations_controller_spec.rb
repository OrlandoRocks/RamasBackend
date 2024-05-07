# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::RegistrationsController", type: :request do
  let(:user_params) do
    { user: { email: "test@example.com", password: "password", password_confirmation: "password" } }
  end

  let(:user) { build(:user, persisted: false) }

  describe "POST /users" do
    context "when registration is successful" do
      before do
        post user_registration_path, params: user_params
      end

      it "returns a success message" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to eq("Se armo el guiso ya te logueaste :D")
      end

      it "returns the user data" do
        expect(response.parsed_body["user"]["email"]).to eq("test@example.com")
      end
    end

    context "when registration fails" do
      before do
        allow(user).to receive(:persisted?).and_return(false)
        post user_registration_path, params: user_params
      end

      it "returns a failure message" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["message"]).to eq("Algo valio shit :(")
      end
    end
  end
end
