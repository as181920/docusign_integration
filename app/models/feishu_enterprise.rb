class FeishuEnterprise < ApplicationRecord
  audited

  belongs_to :tenant, class_name: "TenantAuth::Tenant"

  enum :status, {
    active: "active",
    inactive: "inactive"
  }, default: :active

  validates :tenant_key, presence: true, uniqueness: true
  validates :tenant_id, uniqueness: true
end
