# frozen_string_literal: true

FactoryBot.define do
  factory :land do
    residential
    address { "MyString" }
    block { "MyString" }
    size { 1.5 }
    price { "9.99" }
    house_number { "MyString" }
  end
end
