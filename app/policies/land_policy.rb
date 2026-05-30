# frozen_string_literal: true

class LandPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if super_user?
      return scope.joins(residential: :users).where(users: { id: user.id }).distinct if staff? || seller?

      scope.none
    end
  end

  def index?
    authenticated? && !client?
  end

  def show?
    (manage_business_resources? || seller?) && assigned_to_residential?(record.residential)
  end

  def create?
    return manage_business_resources? if record.is_a?(Class)

    (manage_business_resources? || seller?) && assigned_to_residential?(record.residential)
  end

  def update?
    manage_business_resources? && assigned_to_residential?(record.residential)
  end

  def destroy?
    manage_business_resources? && assigned_to_residential?(record.residential)
  end

  def geojson_collection?
    index?
  end
end
