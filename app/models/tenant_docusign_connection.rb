class TenantDocusignConnection < ApplicationRecord
  audited

  belongs_to :tenant, class_name: "TenantAuth::Tenant"
  belongs_to :connected_by_tenant_user, class_name: "TenantAuth::User", optional: true

  has_many :contract_envelopes, dependent: :restrict_with_error

  enum :status, {
    active: "active",
    expired: "expired",
    revoked: "revoked"
  }, default: :active

  validates :docusign_account_id, presence: true, uniqueness: true
  validates :tenant_id, uniqueness: true
end
