require "test_helper"

class ExternalIdentityTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:external_identity), :valid?
  end

  test "requires provider and provider_uid" do
    tenant = create(:tenant, :acme)
    user = create(:platform_user, name: "platform_alice")
    identity = ExternalIdentity.new(tenant: tenant, user: user)

    assert_not identity.valid?
    assert identity.errors.of_kind?(:provider, :blank)
    assert identity.errors.of_kind?(:provider_uid, :blank)
  end

  test "feishu scope only returns feishu identities" do
    create(:external_identity, provider: "feishu")
    create(:external_identity, provider: "feishu")

    assert_equal ExternalIdentity.count, ExternalIdentity.feishu.count
  end
end
