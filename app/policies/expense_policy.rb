# frozen_string_literal: true

# Policy for expense
class ExpensePolicy < ApplicationPolicy
  # Scope class for expense
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    user.admin? || user.user?
  end

  def index?
    user.admin? || user.user?
  end

  def create?
    user.user?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
