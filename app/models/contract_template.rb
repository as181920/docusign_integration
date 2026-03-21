class ContractTemplate < ApplicationRecord
  audited

  belongs_to :tenant, class_name: "TenantAuth::Tenant"

  enum :status, {
    active: "active",
    deprecated: "deprecated"
  }, default: :active

  validates :name, presence: true
  validates :version, numericality: { greater_than: 0 }
  validates :name, uniqueness: { scope: %i[tenant_id version] }
end
