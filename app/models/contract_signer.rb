class ContractSigner < ApplicationRecord
  audited associated_with: :contract

  belongs_to :contract

  enum :signing_type, {
    signer: "signer",
    carbon_copy: "carbon_copy"
  }, default: :signer

  enum :status, {
    pending: "pending",
    delivered: "delivered",
    completed: "completed",
    declined: "declined"
  }, default: :pending

  validates :name, :email, :role_name, presence: true
  validates :email, uniqueness: { scope: %i[contract_id role_name] }
end
