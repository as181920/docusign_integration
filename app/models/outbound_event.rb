class OutboundEvent < ApplicationRecord
  audited

  belongs_to :tenant, class_name: "TenantAuth::Tenant", optional: true

  enum :status, {
    pending: "pending",
    processing: "processing",
    sent: "sent",
    failed: "failed"
  }, default: :pending

  validates :event_name, presence: true
end
