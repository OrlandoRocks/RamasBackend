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

  def owns_residential?(residential)
    return false unless residential && seller?

    residential.user_id == user.id
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
  end
end
