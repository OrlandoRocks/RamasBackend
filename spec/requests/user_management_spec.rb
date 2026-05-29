# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User management" do
  before do
    %w[super_user admin user client].each { |name| Role.find_or_create_by!(name: name) }
  end

  let(:super_user_role) { Role.find_by!(name: "super_user") }
  let(:admin_role) { Role.find_by!(name: "admin") }
  let(:seller_role) { Role.find_by!(name: "user") }

  let(:super_user) { create(:user, role: super_user_role) }
  let(:admin) { create(:user, role: admin_role) }
  let(:seller) { create(:user, role: seller_role) }

  describe "GET /users" do
    it "returns users and assignable roles for super_user" do
      sign_in(super_user)
      get "/users", headers: @headers

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to be_an(Array)
      expect(json["meta"]["roles"]).to be_an(Array)
      expect(json["meta"]["roles"].map { |r| r["name"] }).to include("admin", "user", "client")
    end

    it "forbids admin" do
      sign_in(admin)
      get "/users", headers: @headers

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids unauthenticated requests" do
      get "/users"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /users" do
    let(:admin_role_record) { Role.find_by!(name: "admin") }

    it "creates a user for super_user" do
      sign_in(super_user)
      post "/users",
           params: {
             user: {
               name: "Jane",
               last_name: "Admin",
               email: "jane.admin@example.com",
               password: "password",
               role_id: admin_role_record.id
             }
           },
           headers: @headers

      expect(response).to have_http_status(:created)
      expect(json["data"]["attributes"]["email"]).to eq("jane.admin@example.com")
      expect(json["data"]["attributes"]["role-name"]).to eq("admin")
    end

    it "forbids seller" do
      sign_in(seller)
      post "/users",
           params: {
             user: {
               name: "Jane",
               last_name: "Admin",
               email: "blocked@example.com",
               password: "password",
               role_id: admin_role_record.id
             }
           },
           headers: @headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /users/:id" do
    let(:target) { create(:user, role: seller_role, name: "Old") }

    it "updates a user for super_user" do
      sign_in(super_user)
      patch "/users/#{target.id}",
            params: { user: { name: "New" } },
            headers: @headers

      expect(response).to have_http_status(:ok)
      expect(json["data"]["attributes"]["name"]).to eq("New")
    end
  end

  describe "DELETE /users/:id" do
    it "deletes another user" do
      manager = create(:user, role: super_user_role)
      other = create(:user, role: seller_role)

      sign_in(manager)
      delete "/users/#{other.id}", headers: @headers

      expect(response).to have_http_status(:ok)
      expect(User.exists?(other.id)).to be(false)
    end

    it "prevents deleting yourself" do
      sign_in(super_user)
      delete "/users/#{super_user.id}", headers: @headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(User.exists?(super_user.id)).to be(true)
    end
  end
end
