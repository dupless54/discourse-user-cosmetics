# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::Integration do
  describe "public contract manifest" do
    it "exposes a stable version and the capabilities loaded on this plugin stack" do
      expect(described_class.contract_version).to eq(1)
      expect(described_class.contract_manifest).to eq(
        version: 1,
        capabilities: {
          ownership: true,
          entitlements: true,
          grants: true,
          selections: true,
          loadouts: true,
          showcase: true,
        },
      )
    end

    it "answers capability support without raising for unknown values" do
      expect(described_class.supports?(:selections)).to eq(true)
      expect(described_class.supports?("loadouts")).to eq(true)
      expect(described_class.supports?(:not_a_real_capability)).to eq(false)
      expect(described_class.supports?(nil)).to eq(false)
    end

    it "returns a fresh capabilities hash so consumers cannot mutate contract state" do
      capabilities = described_class.capabilities
      capabilities[:ownership] = false

      expect(described_class.capabilities[:ownership]).to eq(true)
    end
  end
end
