# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

admin_role = Role.create(name: 'admin')
Role.create(name: 'client')
Role.create(name: 'user')

User.create(email: 'admin@user.com', password: 'password', name: 'Admin', last_name: 'User', role: admin_role)
