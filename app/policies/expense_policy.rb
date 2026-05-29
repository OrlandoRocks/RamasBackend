# frozen_string_literal: true

class ExpensePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if staff?

      return scope.joins(:residential).where(residentials: { user_id: user.id }) if seller?

      scope.none
    end
  end

  def index?
    authenticated? && !client?
  end

  def show?
    manage_business_resources? ||
      (seller? && record.residential&.user_id == user.id)
  end

  def create?
    manage_business_resources? ||
      (seller? &&
        owns_residential?(Residential.find_by(id: record.residential_id)) &&
        record.user_id == user.id)
  end

  def update?
    manage_business_resources?
  end

  def destroy?
    manage_business_resources?
  end
end
