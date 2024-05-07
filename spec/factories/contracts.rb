FactoryBot.define do
  factory :contract do
    client { nil }
    land { nil }
    contract_date { "2024-03-22" }
    type { "" }
    down_payment { "9.99" }
    monthly_payment { "9.99" }
    yearly_payment { "9.99" }
    months { 1.5 }
    penalty_interest { "9.99" }
    extraordinary_payment { "9.99" }
  end
end
