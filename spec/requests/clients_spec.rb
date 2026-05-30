# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Clients" do
  let(:admin_role) { Role.find_or_create_by!(name: "admin") }
  let(:user) { create(:user, role: admin_role) }
  let(:residential) { create(:residential, assigned_user: user) }
  let!(:clients) do
    create_list(:client, 3).each do |client|
      ResidentialClient.create!(client: client, residential: residential)
    end
  end

  before do
    sign_in(user)
  end

  describe "GET /clients" do
    it "returns a successful response and a list of clients" do
      get '/clients', headers: @headers
      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(clients.size)
      clients.each do |client|
        expect(json.map { |c| c['id'] }).to include(client.id)
      end
    end
  end
end
