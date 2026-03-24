class ContractTemplateRole < ApplicationRecord
  audited

  belongs_to :contract_template

  enum :signing_type, {
    signer: "signer",
    carbon_copy: "carbon_copy"
  }, default: :signer

  validates :role_name, presence: true
  validates :routing_order, numericality: { greater_than: 0 }
  validates :role_name, uniqueness: { scope: %i[contract_template_id signing_type] }
end
