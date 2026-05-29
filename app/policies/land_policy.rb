# frozen_string_literal: true

class LandPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if user.super_user? || user.admin?

      if user.seller?
        return scope.joins(:residential).where(residentials: { user_id: user.id })
      end

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
    return manage_business_resources? if record.is_a?(Class)

    manage_business_resources? || (seller? && owns_residential?(record.residential))
  end

  def update?
    manage_business_resources?
  end

  def destroy?
    manage_business_resources?
  end

  def geojson_collection?
    index?
  end
end
