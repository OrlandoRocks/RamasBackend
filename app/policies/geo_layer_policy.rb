# frozen_string_literal: true

class GeoLayerPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if staff?

      return scope.joins(:residential).where(residentials: { user_id: user.id }) if seller?

      scope.none
    end
  end

  def index?
    authenticated? && !client?
  end

  def show?
    manage_business_resources? ||
      (seller? && owns_residential?(record.residential))
  end

  def create?
    manage_business_resources? ||
      (seller? && owns_residential?(Residential.find_by(id: record.residential_id)))
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

  def preview_shapefile?
    index?
  end
end
