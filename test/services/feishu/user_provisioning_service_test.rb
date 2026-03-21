require "test_helper"

module Feishu
  class UserProvisioningServiceTest < ActiveSupport::TestCase
    test "creates external identity for new provider uid" do
      tenant = create(:tenant, :acme)
      platform_user = create(:platform_user, name: "platform_bob")
      tenant_user = create(:tenant_user, :alice, tenant: tenant)

      UserProvisioningService.stubs(:create_platform_user).returns(platform_user)
      UserProvisioningService.stubs(:create_tenant_user).returns(tenant_user)

      assert_difference "ExternalIdentity.count", +1 do
        identity = UserProvisioningService.call(
          tenant: tenant,
          auth_info: {
            "union_id" => "union_new_user",
            "open_id" => "open_new_user",
            "name" => "New Feishu User"
          }
        )

        assert_equal "feishu", identity.provider
        assert_equal tenant.id, identity.tenant_id
        assert_equal platform_user.id, identity.user_id
        assert_equal tenant_user.id, identity.tenant_user_id
      end
    end

    test "reuses existing identity when provider_uid matches" do
      tenant = create(:tenant, :acme)
      existing = create(
        :external_identity,
        tenant: tenant,
        provider: "feishu",
        provider_uid: "union_acme_alice",
        union_id: "union_acme_alice",
        open_id: "open_acme_alice"
      )

      identity = UserProvisioningService.call(
        tenant: tenant,
        auth_info: {
          "union_id" => existing.union_id,
          "open_id" => existing.open_id,
          "name" => "Updated Name"
        }
      )

      assert_equal existing.id, identity.id
      assert_equal "Updated Name", identity.reload.name
    end

    test "raises when union_id and open_id are both missing" do
      assert_raises(ArgumentError) do
        UserProvisioningService.call(tenant: create(:tenant, :acme), auth_info: { "name" => "X" })
      end
    end
  end
end
