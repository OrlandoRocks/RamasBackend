# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contract, type: :model do
  describe "after_save" do
    it "links the client to the land residential" do
      client = create(:client)
      residential = create(:residential)
      land = create(:land, residential: residential)
      create(:contract, client: client, land: land)

      expect(client.residential_ids).to include(residential.id)
    end
  end
end
