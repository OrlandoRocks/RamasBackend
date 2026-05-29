# frozen_string_literal: true

class ContractPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if staff?

      return scope.joins(land: :residential).where(residentials: { user_id: user.id }) if seller?

      return scope.where(client_id: user.client_id) if client? && user.client_id.present?

      scope.none
    end
  end

  def index?
    authenticated?
  end

  def show?
    manage_business_resources? ||
      (seller? && sellers_contract?(record)) ||
      client_own_contract?(record)
  end

  def create?
    manage_business_resources? ||
      (seller? && sellers_land?(land_for(record)))
  end

  def update?
    manage_business_resources?
  end

  def destroy?
    manage_business_resources?
  end

  def payments?
    show?
  end

  private

  def land_for(contract)
    return unless contract.respond_to?(:land_id)

    Land.find_by(id: contract.land_id)
  end

  def sellers_land?(land)
    land&.residential&.user_id == user.id
  end

  def sellers_contract?(contract)
    sellers_land?(contract&.land)
  end

  def client_own_contract?(contract)
    client? && user.client_id.present? && contract.client_id == user.client_id
  end
end
