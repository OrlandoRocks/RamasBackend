require 'rails_helper'

RSpec.describe "Land Serialization", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:residential) { FactoryBot.create(:residential, user: user, name: "Test Residential") }
  let(:land) { FactoryBot.create(:land, residential: residential, land_code: "L-01", address: "Street 1", block: "A", size: 100.0, price: 50000.0, house_number: "123") }
  let(:client) { FactoryBot.create(:client, full_name: "John Doe") }
  let!(:contract) { FactoryBot.create(:contract, land: land, client: client) }

  let(:token) { 
    payload = { user_id: user.id }
    JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
  }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /lands/:id" do
    it "returns all required fields for the land endpoint" do
      get "/lands/#{land.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response).to include(
        "id" => land.id,
        "land_code" => "L-01",
        "client_name" => "John Doe",
        "client_id" => client.id,
        "contract_id" => contract.id
      )
    end
  end

  describe "GET /lands" do
    it "returns all required fields for the index endpoint" do
      get "/lands", headers: headers

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response.first).to include(
        "id" => land.id,
        "land_code" => "L-01",
        "client_name" => "John Doe",
        "client_id" => client.id,
        "contract_id" => contract.id
      )
    end
  end
end
