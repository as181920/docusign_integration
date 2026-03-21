class AuditLog < ApplicationRecord
  belongs_to :tenant, class_name: "TenantAuth::Tenant", optional: true

  validates :action, presence: true
end
