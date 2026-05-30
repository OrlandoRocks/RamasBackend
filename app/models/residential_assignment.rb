# frozen_string_literal: true

class ResidentialAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :residential

  validates :user_id, uniqueness: { scope: :residential_id }
end
