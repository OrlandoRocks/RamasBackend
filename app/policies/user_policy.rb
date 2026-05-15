# frozen_string_literal: true

# Policy for user
class UserPolicy < ApplicationPolicy
  # Scope class for user
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    user.admin?
  end

  def index?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
