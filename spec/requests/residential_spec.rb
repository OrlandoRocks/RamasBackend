# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Residentials" do
  let(:admin_role) { Role.find_or_create_by!(name: "admin") }
  let(:admin) { create(:user, role: admin_role) }
  let!(:residentials) { create_list(:residential, 3) }

  describe "GET /residentials" do
    context "when the user is an admin" do
      before do
        residentials.each { |residential| residential.users << admin unless residential.users.include?(admin) }
        sign_in(admin)
      end
      it "returns a successful response and a list of residentials" do
        get "/residentials", headers: @headers
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(residentials.size)
      end
    end

    context "when the user is not signed in" do
      it "returns an unauthorized response" do
        get "/residentials", headers: @headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
