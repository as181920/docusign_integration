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

  def self.ransackable_attributes(_auth_object = nil)
    %w[id provider event_type delivery_id external_event_id status created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
