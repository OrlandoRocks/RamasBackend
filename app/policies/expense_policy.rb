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
    true
  end

  def index?
    true
  end

  def create?
    user.admin? || record.user?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
