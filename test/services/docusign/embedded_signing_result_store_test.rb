require "test_helper"

module Docusign
  class EmbeddedSigningResultStoreTest < ActiveSupport::TestCase
    setup do
      @cache = ActiveSupport::Cache::MemoryStore.new
      Rails.stubs(:cache).returns(@cache)

      @tenant = create(:tenant, :acme)
      @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
      @contract = create(:contract, :acme_contract, tenant: @tenant, creator_tenant_user: @tenant_user)
    end

    teardown do
      Rails.unstub(:cache)
    end

    test "write and read_once returns payload" do
      ref = EmbeddedSigningResultStore.write(
        contract: @contract,
        signer_email: "signer@example.com",
        signing_url: "https://docusign.example.com/sign/abc"
      )
      payload = EmbeddedSigningResultStore.read_once(contract: @contract, ref: ref)

      assert_equal "signer@example.com", payload[:signer_email]
      assert_equal "https://docusign.example.com/sign/abc", payload[:signing_url]
    end

    test "read_once deletes payload after first read" do
      ref = EmbeddedSigningResultStore.write(
        contract: @contract,
        signer_email: "signer@example.com",
        signing_url: "https://docusign.example.com/sign/abc"
      )

      EmbeddedSigningResultStore.read_once(contract: @contract, ref: ref)
      payload = EmbeddedSigningResultStore.read_once(contract: @contract, ref: ref)

      assert_nil payload
    end

    test "read_once returns nil when contract does not match" do
      other_tenant = create(:tenant, :beta)
      other_user = create(:tenant_user, :bob, tenant: other_tenant)
      other_contract = create(:contract, :beta_contract, tenant: other_tenant, creator_tenant_user: other_user)
      ref = EmbeddedSigningResultStore.write(
        contract: @contract,
        signer_email: "signer@example.com",
        signing_url: "https://docusign.example.com/sign/abc"
      )
      payload = EmbeddedSigningResultStore.read_once(contract: other_contract, ref: ref)

      assert_nil payload
    end
  end
end
