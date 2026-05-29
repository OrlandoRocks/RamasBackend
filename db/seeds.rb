# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

admin_role = Role.find_or_create_by!(name: "admin")
Role.find_or_create_by!(name: "client")
Role.find_or_create_by!(name: "user")
Role.find_or_create_by!(name: "super_user")

User.find_or_create_by!(email: "admin@user.com") do |u|
  u.password = "password"
  u.name = "Admin"
  u.last_name = "User"
  u.role = admin_role
end
