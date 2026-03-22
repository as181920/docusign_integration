require "test_helper"

class RansackAllowlistTest < ActiveSupport::TestCase
  MODELS = [
    AuditLog,
    Contract,
    ContractEnvelope,
    ContractSigner,
    ContractTemplate,
    ExternalIdentity,
    FeishuEnterprise,
    OutboundEvent,
    TenantDocusignConnection,
    WebhookEvent
  ].freeze

  test "all models expose ransack allowlists" do
    MODELS.each do |model_class|
      attributes = model_class.ransackable_attributes(nil)
      associations = model_class.ransackable_associations(nil)

      assert_kind_of Array, attributes, "#{model_class} attributes should be array"
      assert_kind_of Array, associations, "#{model_class} associations should be array"
      assert_includes attributes, "id", "#{model_class} should allow ransack on id"
    end
  end
end
