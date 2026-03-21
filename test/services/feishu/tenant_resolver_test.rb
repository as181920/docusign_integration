require "test_helper"

module Feishu
  class TenantResolverTest < ActiveSupport::TestCase
    test "resolves tenant when tenant key matches" do
      tenant = create(:tenant, :acme)
      create(:feishu_enterprise, :acme_enterprise, tenant: tenant)

      resolved = TenantResolver.resolve!(tenant_uid: "acme", tenant_key: "fs_acme_key")

      assert_equal tenant.id, resolved.id
    end

    test "resolves tenant when tenant key blank" do
      tenant = create(:tenant, :acme)
      create(:feishu_enterprise, :acme_enterprise, tenant: tenant)

      resolved = TenantResolver.resolve!(tenant_uid: "acme", tenant_key: nil)

      assert_equal tenant.id, resolved.id
    end

    test "raises mismatch when tenant key conflicts" do
      tenant = create(:tenant, :acme)
      create(:feishu_enterprise, :acme_enterprise, tenant: tenant)

      assert_raises(Feishu::TenantResolver::MismatchError) do
        TenantResolver.resolve!(tenant_uid: "acme", tenant_key: "wrong-key")
      end
    end
  end
end
