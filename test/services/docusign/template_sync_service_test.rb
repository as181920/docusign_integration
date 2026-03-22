require "test_helper"

module Docusign
  class TemplateSyncServiceTest < ActiveSupport::TestCase
    def create_connection(status: :active)
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      connection = create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
      connection.update!(status: status)
      [tenant, connection]
    end

    test "syncs templates with pagination and returns summary counts" do
      tenant, connection = create_connection

      create_local_templates(tenant)
      stub_template_pages(connection)

      result = TemplateSyncService.call(tenant: tenant, page_size: 2, max_pages: 5)

      assert_equal 4, result[:total_count]
      assert_equal 2, result[:created_count]
      assert_equal 1, result[:updated_count]
      assert_equal 1, result[:skipped_count]
    end

    test "sync updates existing docusign-synced template metadata" do
      tenant, connection = create_connection
      existing = create_local_templates(tenant)
      stub_template_pages(connection)

      TemplateSyncService.call(tenant: tenant, page_size: 2, max_pages: 5)

      existing.reload

      assert_equal "Sales Contract Updated", existing.name
      assert_equal "Updated description", existing.description
      assert_equal "docusign_sync", existing.metadata["template_source"]
      assert_predicate existing.metadata["docusign_synced_at"], :present?
    end

    test "sync creates new templates with expected versions" do
      tenant, connection = create_connection
      create_local_templates(tenant)
      stub_template_pages(connection)

      TemplateSyncService.call(tenant: tenant, page_size: 2, max_pages: 5)

      new_sales_template = ContractTemplate.find_by!(tenant: tenant, docusign_template_id: "tpl-002")

      assert_equal "Sales Contract", new_sales_template.name
      assert_equal 1, new_sales_template.version

      new_nda_template = ContractTemplate.find_by!(tenant: tenant, docusign_template_id: "tpl-003")

      assert_equal "NDA Template", new_nda_template.name
      assert_equal 2, new_nda_template.version
    end

    test "raises when active docusign connection is missing" do
      tenant, _connection = create_connection(status: :expired)

      assert_raises(ActiveRecord::RecordNotFound) do
        TemplateSyncService.call(tenant: tenant)
      end
    end

    private

      def create_local_templates(tenant)
        existing = create(
          :contract_template,
          tenant: tenant,
          name: "Sales Contract",
          version: 1,
          docusign_template_id: "tpl-existing",
          metadata: { "template_source" => "docusign_sync" }
        )
        create(:contract_template, tenant: tenant, name: "NDA Template", version: 1, docusign_template_id: nil)
        existing
      end

      def stub_template_pages(connection)
        Docusign::ApiClient.expects(:get).with(connection: connection, path: "/templates?count=2").returns(
          {
            "envelopeTemplates" => [
              { "templateId" => "tpl-existing", "name" => "Sales Contract Updated", "description" => "Updated description" },
              { "templateId" => "tpl-002", "name" => "Sales Contract", "description" => "New sales contract" }
            ],
            "nextUri" => "/v2.1/accounts/acct_acme/templates?count=2&start_position=3"
          }
        )
        Docusign::ApiClient.expects(:get).with(connection: connection, path: "/templates?count=2&start_position=3").returns(
          {
            "envelopeTemplates" => [
              { "templateId" => "tpl-003", "name" => "NDA Template", "description" => "NDA sync template" },
              { "name" => "missing-id" }
            ]
          }
        )
      end
  end
end
