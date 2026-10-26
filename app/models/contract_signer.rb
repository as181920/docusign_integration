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

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name email role_name routing_order signing_type status created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
