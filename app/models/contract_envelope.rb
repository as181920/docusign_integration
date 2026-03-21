class ContractEnvelope < ApplicationRecord
  audited associated_with: :contract

  belongs_to :contract
  belongs_to :tenant_docusign_connection

  enum :status, {
    created: "created",
    sent: "sent",
    delivered: "delivered",
    completed: "completed",
    declined: "declined",
    voided: "voided"
  }, default: :created

  validates :envelope_id, presence: true, uniqueness: true
end
