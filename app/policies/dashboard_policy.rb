# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  def pending_payments?
    staff? || seller?
  end
end
