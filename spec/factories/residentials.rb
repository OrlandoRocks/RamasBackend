# frozen_string_literal: true

FactoryBot.define do
  factory :residential do
    name { Faker::Address.community }
    address { Faker::Address.full_address }
    association :user, factory: :user
  end
end
