module Feishu
  class UserProvisioningService
    class << self
      def call(tenant:, auth_info:)
        union_id = auth_info[:union_id].presence || auth_info["union_id"].presence
        open_id = auth_info[:open_id].presence || auth_info["open_id"].presence
        name = auth_info[:name].presence || auth_info["name"].presence
        avatar_url = auth_info[:avatar_url].presence || auth_info["avatar_url"].presence
        provider_uid = union_id || open_id

        raise ArgumentError, "union_id/open_id is required" if provider_uid.blank?

        identity = ExternalIdentity.find_or_initialize_by(
          tenant: tenant,
          provider: "feishu",
          provider_uid: provider_uid
        )

        user = identity.user || find_existing_platform_user(union_id:, open_id:) || create_platform_user(provider_uid:, name:)
        tenant_user = identity.tenant_user || find_existing_tenant_user(tenant:, user:) || create_tenant_user(tenant:, provider_uid:, name:)

        identity.user = user
        identity.tenant_user = tenant_user
        identity.union_id = union_id
        identity.open_id = open_id
        identity.name = name
        identity.avatar_url = avatar_url
        identity.metadata = identity.metadata.to_h.merge(auth_info.stringify_keys)
        identity.save!

        identity
      end

      private

        def find_existing_platform_user(union_id:, open_id:)
          existing_identity = ExternalIdentity.feishu
          existing_identity = existing_identity.where(union_id: union_id) if union_id.present?
          existing_identity = existing_identity.where(open_id: open_id) if union_id.blank? && open_id.present?

          user_id = existing_identity.where.not(user_id: nil).pick(:user_id)
          return nil if user_id.blank?

          UserAuth::User.find_by(id: user_id)
        end

        def find_existing_tenant_user(tenant:, user:)
          tenant_user_id = ExternalIdentity.where(tenant:, user:).where.not(tenant_user_id: nil).pick(:tenant_user_id)
          return nil if tenant_user_id.blank?

          TenantAuth::User.find_by(id: tenant_user_id, tenant_id: tenant.id)
        end

        def create_platform_user(provider_uid:, name:)
          base_name = name.presence || "feishu_#{provider_uid.last(10)}"
          candidate_name = base_name
          suffix = 1

          while UserAuth::User.exists?(name: candidate_name)
            suffix += 1
            candidate_name = "#{base_name}_#{suffix}"
          end

          UserAuth::User.create!(name: candidate_name, password: SecureRandom.hex(16))
        end

        def create_tenant_user(tenant:, provider_uid:, name:)
          base_name = name.presence || "feishu_#{provider_uid.last(10)}"
          candidate_name = base_name
          suffix = 1

          while TenantAuth::User.exists?(tenant_id: tenant.id, name: candidate_name)
            suffix += 1
            candidate_name = "#{base_name}_#{suffix}"
          end

          TenantAuth::User.create!(tenant:, name: candidate_name, password: SecureRandom.hex(16))
        end
    end
  end
end
