# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  protected

  def authenticated?
    user.present?
  end

  def super_user?
    user&.super_user?
  end

  def admin?
    user&.admin?
  end

  # Pundit "user" prop is the Rails User model — role.name "user" is the seller / vendedor
  def seller?
    user&.seller?
  end

  def client?
    user&.client?
  end

  def staff?
    user&.staff?
  end

  def manage_all?
    super_user?
  end

  # Residentials, lands, contracts, payments, expenses, clients (not users)
  def manage_business_resources?
    super_user? || admin?
  end

  # Whether the user is assigned to this residential (sellers/admins) or is super_user.
  def assigned_to_residential?(residential)
    return false unless user && residential
    return true if super_user?

    user.residentials.exists?(residential.id)
  end

  def client_visible?(client)
    return false unless user && client
    return true if super_user?
    return true if client? && user.client_id.present? && client.id == user.client_id

    client.residentials.joins(:users).where(users: { id: user.id }).exists?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

    protected

    def super_user?
      user&.super_user?
    end

    def admin?
      user&.admin?
    end

    def seller?
      user&.seller?
    end

    def client?
      user&.client?
    end

    def staff?
      user&.staff?
    end

    def assigned_residential_ids
      @assigned_residential_ids ||= user.residential_ids
    end

    # Scope a relation that belongs to / joins residentials assigned to this user.
    def scope_to_assigned_residentials(relation, residential_table: "residentials")
      return relation.none unless user
      return relation.all if super_user?

      relation.joins(residential: :users).where(users: { id: user.id })
    end
  end
end
