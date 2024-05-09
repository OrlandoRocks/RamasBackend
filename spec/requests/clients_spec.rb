# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Clients" do
  let!(:clients) { create_list(:client, 3) }
  let(:user) { create(:user, role: create(:role)) }

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
