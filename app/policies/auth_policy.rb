# frozen_string_literal: true

# Headless policy for auth endpoints (e.g. logout).
class AuthPolicy < ApplicationPolicy
  def logout?
    authenticated?
  end
end
