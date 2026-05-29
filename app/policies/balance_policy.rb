# frozen_string_literal: true

# Financial / balance aggregates (BalancesController)
class BalancePolicy < ApplicationPolicy
  def all_residentials?
    staff? || seller?
  end

  def residentials_list?
    staff? || seller?
  end

  def get_balance_data?
    staff? || seller?
  end
end
