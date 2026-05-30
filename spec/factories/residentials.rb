# frozen_string_literal: true

FactoryBot.define do
  factory :residential do
    name { Faker::Address.community }
    address { Faker::Address.full_address }

    transient do
      assigned_user { nil }
    end

    after(:create) do |residential, evaluator|
      user = evaluator.assigned_user || create(:user, role: Role.find_or_create_by!(name: "user"))
      residential.users << user unless residential.users.exists?(user.id)
    end
  end
end
