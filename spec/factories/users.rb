# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password" }
    name { Faker::Name.name }
    last_name { Faker::Name.last_name }
    association :role, factory: :role
  end
end
