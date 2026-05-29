# frozen_string_literal: true

class ClientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if staff? || seller?

      scope.none
    end
  end

  def index?
    staff? || seller?
  end

  def show?
    staff? || seller?
  end

  def create?
    manage_business_resources?
  end

  def update?
    manage_business_resources?
  end

  def destroy?
    manage_business_resources?
  end
end
