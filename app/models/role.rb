# frozen_string_literal: true

# Description: Role model that has many users.
class Role < ApplicationRecord
  has_many :users, dependent: :nullify
end
