# frozen_string_literal: true

# Description: Client model that has many contracts, lands, residential, payments and users through contracts.
class Land < ApplicationRecord
  belongs_to :residential

  has_one :contract, dependent: :nullify
  has_one :client, through: :contract
  has_many :payments, dependent: :nullify
end
