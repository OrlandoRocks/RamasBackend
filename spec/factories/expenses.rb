# frozen_string_literal: true

FactoryBot.define do
  factory :expense do
    residential { nil }
    user { nil }
    account { "MyString" }
    department { "MyString" }
    type { "" }
    comments { "MyString" }
    amount { "9.99" }
  end
end
