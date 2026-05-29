# frozen_string_literal: true

require "rails_helper"

RSpec.describe Client, type: :model do
  let(:client) { build(:client) }

  describe "document validations" do
    it "requires all three documents when validate_documents is true" do
      client.validate_documents = true
      expect(client).not_to be_valid
      expect(client.errors.attribute_names).to include(:ine_document, :tax_document, :proof_of_address_document)
    end

    it "rejects invalid content type" do
      client.ine_document.attach(
        io: StringIO.new("not-a-real-pdf"),
        filename: "evil.exe",
        content_type: "application/x-msdownload"
      )
      expect(client).not_to be_valid
      expect(client.errors[:ine_document]).to include("must be a PDF, JPG, or PNG file")
    end
  end
end
