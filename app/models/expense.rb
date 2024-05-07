# frozen_string_literal: true

# Description: Expense model that belongs to a residential and a user.
class Expense < ApplicationRecord
  belongs_to :residential
  belongs_to :user
end
