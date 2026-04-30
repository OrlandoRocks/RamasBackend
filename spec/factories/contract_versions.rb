FactoryBot.define do
  factory :contract_version do
    contract { nil }
    html_content { "MyText" }
    version_number { 1 }
  end
end
