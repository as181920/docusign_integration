class WebhookEvent < ApplicationRecord
  belongs_to :tenant, class_name: "TenantAuth::Tenant", optional: true

  enum :status, {
    received: "received",
    processing: "processing",
    processed: "processed",
    failed: "failed"
  }, default: :received

  validates :provider, :delivery_id, presence: true
  validates :delivery_id, uniqueness: { scope: :provider }
end
