# frozen_string_literal: true

# Description: Model that represents a JWT denylist.
class JwtDenylist < ApplicationRecord
  self.table_name = "jwt_denylist"

  validates :jti, presence: true, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
end
