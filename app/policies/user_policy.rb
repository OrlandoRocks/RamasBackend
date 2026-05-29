# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user&.super_user?

      scope.all
    end
  end

  def index?
    super_user?
  end

  def show?
    super_user?
  end

  # GET /member-data — any authenticated user reading their own profile
  def profile?
    record == user
  end

  def create?
    super_user?
  end

  def update?
    super_user?
  end

  def destroy?
    super_user?
  end
end
