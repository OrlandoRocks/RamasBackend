# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    land { nil }
    amount { "9.99" }
    payment_date { "2024-03-22" }
    payment_type { "MyString" }
    comments { "MyText" }
    image_url { "MyString" }
    status { "MyString" }
  end
end
