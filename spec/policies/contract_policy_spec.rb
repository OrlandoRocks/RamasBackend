# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

RSpec.describe ContractPolicy, type: :policy do
  let(:seller_role) { Role.find_or_create_by!(name: 'user') }
  let(:admin_role) { Role.find_or_create_by!(name: 'admin') }
  let(:client_role) { Role.find_or_create_by!(name: 'client') }

  let(:seller) { create(:user, role: seller_role) }
  let(:admin) { create(:user, role: admin_role) }

  let(:seller_residential) { create(:residential, user: seller) }
  let(:land) { create(:land, residential: seller_residential) }
  let(:client_model) { create(:client) }
  let(:contract) { create(:contract, land: land, client: client_model) }

  let(:portal_client) { create(:user, role: client_role, client: client_model) }

  permissions :index? do
    it 'permits any authenticated subject' do
      expect(described_class).to permit(seller, Contract)
    end
  end

  permissions :show? do
    it 'permits the seller who owns the residential for the contract land' do
      expect(described_class).to permit(seller, contract)
    end

    it 'permits the portal client for their own contract' do
      expect(described_class).to permit(portal_client, contract)
    end

    it 'denies the portal client for another client contract' do
      other_contract = create(:contract)
      expect(described_class).not_to permit(portal_client, other_contract)
    end
  end

  permissions :create? do
    it 'permits seller creating a contract on their own land' do
      new_contract = build(:contract, land: land, client: client_model)
      expect(described_class).to permit(seller, new_contract)
    end

    it 'denies seller creating a contract on another sellers land' do
      other_land = create(:land)
      new_contract = build(:contract, land: other_land, client: client_model)
      expect(described_class).not_to permit(seller, new_contract)
    end
  end

  permissions :update? do
    it 'permits admin' do
      expect(described_class).to permit(admin, contract)
    end

    it 'denies seller' do
      expect(described_class).not_to permit(seller, contract)
    end
  end

  describe ContractPolicy::Scope do
    subject(:resolved) { described_class.new(portal_client, Contract.all).resolve }

    it 'returns only contracts for the portal client profile' do
      other = create(:contract)
      expect(resolved).to include(contract)
      expect(resolved).not_to include(other)
    end
  end
end
