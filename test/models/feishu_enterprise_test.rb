require "test_helper"

class FeishuEnterpriseTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:feishu_enterprise), :valid?
  end

  test "requires unique tenant_key" do
    create(:feishu_enterprise, tenant_key: "fs_acme_key")

    duplicate = FeishuEnterprise.new(
      tenant: create(:tenant, :beta),
      tenant_key: "fs_acme_key"
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:tenant_key, :taken)
  end

  test "allows only one enterprise per tenant" do
    tenant = create(:tenant, :acme)
    create(:feishu_enterprise, tenant: tenant, tenant_key: "fs_acme_key")

    duplicate = FeishuEnterprise.new(
      tenant: tenant,
      tenant_key: "another-key"
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:tenant_id, :taken)
  end

  test "allows blank tenant_key before oauth binding" do
    enterprise = build(:feishu_enterprise, tenant_key: nil)

    assert_predicate enterprise, :valid?
  end
end
