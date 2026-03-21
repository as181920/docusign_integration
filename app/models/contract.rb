class Contract < ApplicationRecord
  audited

  belongs_to :tenant, class_name: "TenantAuth::Tenant"
  belongs_to :creator_tenant_user, class_name: "TenantAuth::User", optional: true

  has_many :contract_signers, dependent: :destroy
  has_one :contract_envelope, dependent: :destroy

  has_many_attached :documents

  enum :status, {
    draft: "draft",
    prepared: "prepared",
    sent: "sent",
    delivered: "delivered",
    signed: "signed",
    declined: "declined",
    voided: "voided",
    archived: "archived"
  }, default: :draft

  validates :title, presence: true
  validates :contract_no, presence: true, uniqueness: { scope: :tenant_id }
end
