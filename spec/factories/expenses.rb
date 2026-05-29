# frozen_string_literal: true

FactoryBot.define do
  factory :expense do
    association :residential
    association :user
    account { "MyString" }
    department { "MyString" }
    expense_type { "general" }
    comments { "MyString" }
    amount { "9.99" }
  end
end
