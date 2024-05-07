# frozen_string_literal: true

# Description: Contract model that belongs to a client and a land and has many users.
class Contract < ApplicationRecord
  belongs_to :client
  belongs_to :land

  has_many :users
end
