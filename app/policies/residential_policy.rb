# frozen_string_literal: true

class ResidentialPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if user.super_user? || user.admin?

      return scope.where(user_id: user.id) if user.seller?

      scope.none
    end
  end

  def index?
    authenticated? && !client?
  end

  def show?
    manage_business_resources? || (seller? && owns_residential?(record))
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

  # Member routes: geojson / lands_geojson — same as show
  def geojson?
    show?
  end

  def lands_geojson?
    show?
  end

  # Shapefile / bulk land import into this development
  def import_lands?
    manage_business_resources? || (seller? && owns_residential?(record))
  end

  # Geo layer import tied to this residential
  def import_geo_layers?
    manage_business_resources? || (seller? && owns_residential?(record))
  end
end
