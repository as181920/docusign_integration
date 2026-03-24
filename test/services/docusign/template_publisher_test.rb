require "test_helper"

module Docusign
  class TemplatePublisherTest < ActiveSupport::TestCase
    test "publishes local template to docusign and updates publish state" do
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      connection = create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
      connection.update!(status: :active)

      template = create(:contract_template, tenant: tenant, docusign_template_id: nil, publish_state: :draft)
      template.documents.attach(io: StringIO.new("fake pdf"), filename: "offer.pdf", content_type: "application/pdf")
      create(:contract_template_role, contract_template: template, role_name: "Employee", signing_type: :signer)

      Docusign::ApiClient.expects(:post).with(connection: connection, path: "/templates", body: kind_of(Hash)).returns(
        { "templateId" => "tpl_remote_001" }
      )

      result = TemplatePublisher.call(template: template)

      template.reload

      assert_equal "tpl_remote_001", result["templateId"]
      assert_equal "tpl_remote_001", template.docusign_template_id
      assert_equal "published", template.publish_state
      assert_predicate template.published_at, :present?
    end

    test "requires at least one document" do
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user, status: :active)
      template = create(:contract_template, tenant: tenant, docusign_template_id: nil, publish_state: :draft)
      create(:contract_template_role, contract_template: template, role_name: "Employee", signing_type: :signer)

      assert_raises(Docusign::Error) do
        TemplatePublisher.call(template: template)
      end
    end
  end
end
