class ExternalIdentity < ApplicationRecord
  audited

  belongs_to :user, class_name: "UserAuth::User"
  belongs_to :tenant, class_name: "TenantAuth::Tenant"
  belongs_to :tenant_user, class_name: "TenantAuth::User", optional: true

  validates :provider, presence: true
  validates :provider_uid, presence: true, uniqueness: { scope: %i[tenant_id provider] }

  scope :feishu, -> { where(provider: "feishu") }
end
