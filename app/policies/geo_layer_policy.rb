# frozen_string_literal: true

class GeoLayerPolicy < ApplicationPolicy
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
    residential = Residential.find_by(id: record.residential_id)
    (manage_business_resources? || seller?) && assigned_to_residential?(residential)
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

  def preview_shapefile?
    index?
  end
end
