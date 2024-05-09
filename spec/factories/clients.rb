# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    code { Faker::Number.number(digits: 10) }
    full_name { Faker::Name.name }
    identification_card { "MyString" }
    rfc { "MyString" }
    address { "MyString" }
    colony { "MyString" }
    zip_code { "MyString" }
    phone_number { Faker::PhoneNumber.cell_phone }
    city { "MyString" }
    state { "MyString" }
    country { "MyString" }
    assignee { "MyString" }
    email { Faker::Internet.email }
    birthday { "MyString" }
    civil_status { "MyString" }
    spouse { "MyString" }
    economic_dependants { false }
    home_owner { false }
    occupation { "MyString" }
    company { Faker::Company.name }
    company_address { "MyString" }
    company_phone { "MyString" }
    monthly_income { "MyString" }
    monthly_expenses { "MyString" }
    comments { "MyText" }
    image { "MyString" }
  end
end
