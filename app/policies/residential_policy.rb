# frozen_string_literal: true

class ResidentialPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if super_user?

      scope.joins(:users).where(users: { id: user.id }).distinct
    end
  end

  def index?
    authenticated? && !client?
  end

  def show?
    (manage_business_resources? || seller?) && assigned_to_residential?(record)
  end

  def create?
    manage_business_resources?
  end

  def update?
    manage_business_resources? && assigned_to_residential?(record)
  end

  def destroy?
    manage_business_resources? && assigned_to_residential?(record)
  end

  def geojson?
    show?
  end

  def lands_geojson?
    show?
  end

  def import_lands?
    (manage_business_resources? || seller?) && assigned_to_residential?(record)
  end

  def import_geo_layers?
    (manage_business_resources? || seller?) && assigned_to_residential?(record)
  end
end
