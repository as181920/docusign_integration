class ContractTemplate < ApplicationRecord
  audited

  belongs_to :tenant, class_name: "TenantAuth::Tenant"

  has_many_attached :documents

  has_many :template_roles,
    class_name: "ContractTemplateRole",
    dependent: :destroy,
    inverse_of: :contract_template

  accepts_nested_attributes_for :template_roles,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs["role_name"].to_s.strip.blank? }

  enum :status, {
    active: "active",
    deprecated: "deprecated"
  }, default: :active

  enum :publish_state, {
    draft: "draft",
    published: "published"
  }, default: :draft

  validates :name, presence: true
  validates :version, numericality: { greater_than: 0 }
  validates :name, uniqueness: { scope: %i[tenant_id version] }

  def published_to_docusign?
    published? && docusign_template_id.present?
  end
end
