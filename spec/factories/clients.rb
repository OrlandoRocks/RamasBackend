FactoryBot.define do
  factory :client do
    code { "MyString" }
    full_name { "MyString" }
    identification_card { "MyString" }
    rfc { "MyString" }
    address { "MyString" }
    colony { "MyString" }
    zip_code { "MyString" }
    phone_number { "MyString" }
    city { "MyString" }
    state { "MyString" }
    contry { "MyString" }
    assignee { "MyString" }
    email { "MyString" }
    birthday { "MyString" }
    nacionality { "MyString" }
    civil_status { "MyString" }
    spouse { "MyString" }
    economic_dependants { false }
    home_owner { false }
    occupation { "MyString" }
    company { "MyString" }
    company_address { "MyString" }
    company_phone { "MyString" }
    monthly_income { "MyString" }
    monthly_expenses { "MyString" }
    comments { "MyText" }
    image { "MyString" }
  end
end
