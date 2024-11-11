# frozen_string_literal: true

# Description: Client model that has many contracts, lands, residentials, payments and users through contracts.
class Residential < ApplicationRecord
  belongs_to :user

  has_many :lands, dependent: :nullify
  has_many :expenses, dependent: :nullify
  has_many :clients, through: :lands
  has_many :contracts, through: :lands
  has_many :payments, through: :contracts
end
