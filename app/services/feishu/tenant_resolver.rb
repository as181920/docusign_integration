module Feishu
  class TenantResolver
    class MismatchError < StandardError; end

    class << self
      # Resolve tenant by URL tenant_uid and verify Feishu tenant_key consistency.
      def resolve(tenant_uid:, tenant_key:)
        tenant = TenantAuth::Tenant.find_by!(uid: tenant_uid)
        enterprise = FeishuEnterprise.find_by!(tenant: tenant)

        return tenant if tenant_key.blank? || enterprise.tenant_key == tenant_key

        raise MismatchError, "tenant_key does not match tenant_uid"
      end
    end
  end
end
