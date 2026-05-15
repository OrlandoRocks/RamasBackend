# frozen_string_literal: true

# Policy for land
class LandPolicy < ApplicationPolicy
  # Scope class for land
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
