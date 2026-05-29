# frozen_string_literal: true

class ClientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if super_user?

      return scope.where(id: user.client_id) if client? && user.client_id.present?

      return scope.joins(:residentials).where(residentials: { id: assigned_residential_ids }).distinct if staff? || seller?

      scope.none
    end
  end

  def index?
    staff? || seller?
  end

  def show?
    client_visible?(record)
  end

  def create?
    manage_business_resources?
  end

  def update?
    return true if client? && user.client_id.present? && record.id == user.client_id

    manage_business_resources? && client_visible?(record)
  end

  def destroy?
    manage_business_resources? && client_visible?(record)
  end
end
