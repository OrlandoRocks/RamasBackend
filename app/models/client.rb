# frozen_string_literal: true

# Description: Client model that has many contracts, lands, residentials, payments and users through contracts.
class Client < ApplicationRecord
  has_many :contracts
  has_many :lands, through: :contracts
  has_many :residentials, through: :lands
  has_many :payments, through: :lands
  has_many :users, through: :contracts
end
